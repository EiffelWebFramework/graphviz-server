note
	description: "GRAPH_HANDLER handle the graph resources, it allow retrieve graph for anonymous users"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPH_HANDLER

inherit

	WSF_URI_HANDLER
		rename
			execute as uri_execute,
			new_mapping as new_uri_mapping
		end

	WSF_URI_TEMPLATE_HANDLER
		rename
			execute as uri_template_execute,
			new_mapping as new_uri_template_mapping
		select
			new_uri_template_mapping
		end

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get
		end

	COLLECTION_JSON_HELPER

	SHARED_DATABASE_API

	REFACTORING_HELPER


feature -- Initialization



feature -- execute

	uri_execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (req, res)
		end

	uri_template_execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (req, res)
		end

feature -- HTTP Methods

		--| Right now conditional GET and PUT are not implemented.

	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found and their corresponding error in collection json
		do
				--| TODO refactor code.
				--| GET need to handle two different kind of request now.
				--| The first case, /graph, mean retrieve all graphs
				--| The second case, /graph/{id} with the path parametrer id,
				--| in this case retrive the graph with the given id.
				--| Maybe the first case need to be refactored and removed to a new
				--| handler possibly the SEARCH_HANLDER.
			initialize_converters (json)
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("id") as l_id and then l_id.is_integer then
						-- retrieve a graph identidied by l_id
					process_graph (req, res, l_id.integer_value)
				else
						-- retrieve all
					process_graphs (req, res)
				end
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; msg: STRING; status_code: INTEGER)
		local
			h: HTTP_HEADER
			l_msg: STRING
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			l_msg := msg
			h.put_content_length (l_msg.count)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code (status_code)
			res.put_header_text (h.string)
			res.put_string (l_msg)
		end

feature -- Graph process

	process_graph (req: WSF_REQUEST; res: WSF_RESPONSE; id: INTEGER)
			-- process a graph identified by `id'
			-- generate the response in CJ
		local
			l_cj : CJ_COLLECTION
		do
				--| We need to handle possible errors with the db layer.
			if attached graph_dao.retrieve_by_id (id) as l_graph then
				l_cj := collection_json_graph (req, l_graph)
				l_cj.add_link (new_link (req.absolute_script_url (graph_uri), "graphs", "Home Graph",Void, Void))
				build_item (req, l_graph, l_cj)
				if attached json.value (l_cj) as l_cj_answer then
					compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.ok)
				end
			else
				l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Resource not found", "001", "The graph id " + id.out + " does not exist in the system"))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
				end
			end
		end

	process_graphs (req: WSF_REQUEST; res: WSF_RESPONSE)
		-- Initial implementation of pagination, righ now it uses a defaul value in case
		-- we came from /graph
		-- After that it can use an expansion of the following uri template /graph{?index,offset}
		-- The client can redefine the offset, but maybe we can take a better approach to define
		-- these values (index, offset)
		local
			l_count : INTEGER
			l_pages : INTEGER
			p_offset : INTEGER
		do
			l_count := graph_dao.retrieve_count
			if  attached {WSF_STRING} req.query_parameter ("offset") as l_offset and then l_offset.is_integer then
				if l_offset.integer_value = 0 then
					p_offset := 0
				else
					p_offset := l_offset.integer_value // 5
				end
				if attached graph_dao.retrieve_page (p_offset, l_offset.integer_value) as graphs then
					if attached {CJ_COLLECTION} collection_json_graph (req, Void) as l_cj then
						across
							graphs as ic
						loop
							build_item (req, ic.item, l_cj)
						end

						l_pages :=  (l_count // 5) + 1
						if l_pages > 1 then
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (0)), "first","Page 1 of " +l_pages.out,Void,Void))
							if l_offset.integer_value >= 5 then
								l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (l_offset.integer_value - 5)), "prev","Page " + (((l_offset.integer_value - 5) // 5)+1).out + " of " +l_pages.out,Void,Void))
							end
							if l_offset.integer_value <= l_count then
								l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (l_offset.integer_value + 5)), "next","Page " + (((l_offset.integer_value + 5) // 5)+1).out + " of "+l_pages.out,Void,Void))
							end
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page ((l_pages-1) * 5)), "last","Page " + l_pages.out + " of "+l_pages.out,Void,Void))
						else
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (l_offset.integer_value)), "first","Page " + l_pages.out + " of "+l_pages.out,Void,Void))
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (l_offset.integer_value)), "last","Page " + l_pages.out + " of "+l_pages.out,Void,Void))
						end
						if attached json.value (l_cj) as l_cj_answer then
							compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.ok)
						end
					end
				end
			else
				l_pages :=  (l_count // 5) + 1 -- Default value
				if attached graph_dao.retrieve_page (0, 5) as graphs then
					if attached {CJ_COLLECTION} collection_json_graph (req, Void) as l_cj then
						across
							graphs as ic
						loop
							build_item (req, ic.item, l_cj)
						end

						if l_pages > 1 then
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (0)), "first","Page 1 of " +l_pages.out,Void,Void))
							if 5  <= l_count then
								l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (5)), "next","Page " + (2).out + " of "+l_pages.out,Void,Void))
							end
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page ((l_pages-1) * 5)), "last","Page " + l_pages.out + " of "+l_pages.out,Void,Void))
						else
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (0)), "first","Page " + l_pages.out + " of "+l_pages.out,Void,Void))
							l_cj.add_link (new_link (req.absolute_script_url(graph_uri_page (0)), "last","Page " + l_pages.out + " of "+l_pages.out,Void,Void))
						end
						if attached json.value (l_cj) as l_cj_answer then
							compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.ok)
						end
					end
				end
			end
		end

feature {NONE} -- Implementacion Repository and Graph Layer

	extract_cj_request (l_post: STRING): detachable GRAPH
			-- extract an object Order from the request, or Void
			-- if the request is invalid
		local
			l_title: detachable STRING_32
			l_content: detachable STRING_32
			l_description: detachable STRING_32
		do
			if attached json_to_cj_template (l_post) as template then
				across
					template.data as ic
				loop
					if ic.item.name.same_string ("title") then
						l_title := ic.item.value
					elseif ic.item.name.same_string ("description") then
						l_description := ic.item.value
					elseif ic.item.name.same_string ("content") then
						l_content := ic.item.value
					end
				end
				if l_content /= Void then
					create Result.make (l_content, l_title, l_description)
				end
			end
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
