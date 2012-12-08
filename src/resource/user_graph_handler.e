note
	description: "USER_GRAPH_HANDLER handle the graph resources for a particular user, it allow create, get one or all, delete and updates graphs per user"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	USER_GRAPH_HANDLER

inherit

	WSF_FILTER_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]
		select
			default_create
		end

	WSF_URI_TEMPLATE_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	WSF_RESOURCE_CONTEXT_HANDLER_HELPER [FILTER_HANDLER_CONTEXT]
		redefine
			do_get,
			do_put,
			do_post,
			do_delete
		end

	SHARED_EJSON

	GRAPHVIZ_SERVER_URI_TEMPLATES

	GRAPH_MANAGER
		rename
			default_create as grm_default_create
		end

	REFACTORING_HELPER

create
	make

feature -- Initialization

	make
		do
			grm_default_create
		end

feature -- execute

feature -- execute

	execute (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (ctx, req, res)
			execute_next (ctx, req, res)
		end

feature -- HTTP Methods

		--| The current implementation will use a simple authentication and authorization schema as a proof of concept
		--| we will inspect the header looking for : User:example and Password: test

		--| Right now conditional GET and PUT are not implemented.

	do_get (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found
		local
			cj_error: CJ_ERROR
		do
				--| TODO refactor code.
				--| GET need to handle two different kind of request now.
				--| The first case, /user/{id}/graph, mean retrieve all graphs, for the
				--| user with id {id}
				--| The second case, /user/{uid}/graph/{gid} with the path parameters uid and gid,
				--| in this case retrive the graph with the given id, for the given user id uid.
				--| Maybe the first case need to be refactored and removed to a new
				--| handler possibly the SEARCH_HANLDER.
			initialize_converters (json)
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {WSF_STRING} req.path_parameter ("gid") as g_id and then g_id.is_integer then
						-- retrieve a graph identidied by uid and gid
					if attached retrieve_by_id_and_user_id (g_id.integer_value, l_id.integer_value) as l_graph then
						if attached collection_json_graph (req, l_id.integer_value, l_graph) as l_cj then
							build_item (req, l_id.integer_value, l_graph, l_cj)
							if attached json.value (l_cj) as l_cj_answer then
								compute_response_get (req, res, l_cj_answer.representation)
							end
						end
					else
						if attached collection_json_graph (req, l_id.integer_value, Void) as l_cj then
							create cj_error.make ("Resource not found", "001", "The graph id " + g_id.out + " does not exist in the system for the user " + l_id.out)
							l_cj.set_error (cj_error)
							if attached json.value (l_cj) as l_cj_answer then
								handle_resource_not_found_response (l_cj_answer.representation, req, res)
							end
						end
					end
				elseif attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer then
						-- retrieve all
					if attached retrieve_all_by_user_id (l_id.integer_value) as graphs then
						if attached collection_json_graph (req, l_id.integer_value, Void) as l_cj then
							across
								graphs as ic
							loop
								build_item (req, l_id.integer_value, ic.item, l_cj)
							end
							if attached json.value (l_cj) as l_cj_answer then
								compute_response_get (req, res, l_cj_answer.representation)
							end
						end
					end
				end
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; msg: STRING)
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
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (l_msg)
		end

	do_post (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Here the convention is the following.
			-- POST is used for creation and the server determines the URI
			-- of the created resource.
			-- If the request post is SUCCESS, the server will create the graph and will response with
			-- HTTP_RESPONSE 201 CREATED, the Location header will contains the newly created graph's URI
			-- if the request post is not SUCCESS, the server will response with
			-- HTTP_RESPONSE 400 BAD REQUEST, the client send a bad request
			-- HTTP_RESPONSE 500 INTERNAL_SERVER_ERROR, when the server can deliver the request
		local
			l_post: STRING
			l_helper: WSF_RESOURCE_HANDLER_HELPER
		do
			create l_helper
			l_post := l_helper.retrieve_data (req)
			if attached extract_cj_request (l_post) as l_graph and then attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer then
					-- save graph
					-- return the location uri of the graph and return a 201
					--| Here maybe we need to verify if the save action in
					--| was succesful or not, if not was successfull, we need to
					--| send a 50x error.
				insert (l_graph, l_id.integer_value)
				l_graph.set_id (last_row_id.to_integer_32)
				compute_response_post (req, res, l_id.integer_value, l_graph)
			else
				handle_bad_request_response (l_post + "%N is not a valid Graph", req, res)
			end
		end

	compute_response_post (req: WSF_REQUEST; res: WSF_RESPONSE; user_id: INTEGER; a_graph: GRAPH)
		local
			h: HTTP_HEADER
			l_location: STRING
		do
				--| Here we send a response with status code 201 and the uri of
				--| the new resource.
				--| Other option is send a 201 and a redirect to http://127.0.0.1:9090/graph
				--| the problem here is that redirect action rewrite the location, I'm not
				--| sure if that behavior is ok.
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			l_location := req.absolute_script_url (user_graph_id_uri (user_id, a_graph.id))
			h.put_location (l_location)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.created)
			res.put_header_text (h.string)
		end

	do_delete (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Here we use DELETE to cancel a graph description.
			-- 200 if is ok
			-- 404 Resource not found
			-- 500 if we have an internal server error
		do
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {WSF_STRING} req.path_parameter ("gid") as g_id and then g_id.is_integer then
					delete_by_id (g_id.integer_value, l_id.integer_value)
					compute_response_delete (req, res)
				else
					handle_resource_not_found_response (orig_path + " not found in this server", req, res)
				end
			end
		end

	compute_response_delete (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.no_content)
			res.put_header_text (h.string)
		end

	do_put (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Updating a resource with PUT
			-- A successful PUT request will not create a new resource, instead it will
			-- change the state of the resource identified by the current uri.
			-- If success we response with 200.
			-- 404 if the graph is not found
			-- 400 in case of a bad request
			-- 500 internal server error
		local
			l_put: STRING
			l_helper: WSF_RESOURCE_HANDLER_HELPER
		do
				--|WSF_RESOURCE_CONTEXT_HANDLER_HELPER does not have a retrieve_data, it should.

			create l_helper
			l_put := l_helper.retrieve_data (req)
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {WSF_STRING} req.path_parameter ("gid") as g_id and then g_id.is_integer then
					if attached extract_cj_request (l_put) as lreq_graph and then attached retrieve_by_id_and_user_id (g_id.integer_value, l_id.integer_value) as ldb_graph then
						ldb_graph.set_description (lreq_graph.description)
						ldb_graph.set_title (lreq_graph.title)
						ldb_graph.set_content (lreq_graph.content)
						update (ldb_graph, l_id.integer_value)
						compute_response_put (req, res)
					else
						handle_resource_not_found_response (orig_path + " not found in this server", req, res)
					end
				end
			end
		end

	compute_response_put (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			h: HTTP_HEADER
		do
				--| Here we send a response with status code 200,
				--| Maybe we also can send a redirect to the resource.
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
		end

feature {NONE} -- Implementacion Repository and Graph Layer

	json_to_cj_template (post: STRING): detachable CJ_TEMPLATE
		local
			parser: JSON_PARSER
		do
			initialize_converters (json)
			create parser.make_parser (post)
			if attached parser.parse_object as cj and parser.is_parsed then
				if attached {CJ_TEMPLATE} json.object (cj.item ("template"), "CJ_TEMPLATE") as l_col then
					Result := l_col
				end
			end
		end

	initialize_converters (j: like json)
			-- Initialize json converters
		do
			j.add_converter (create {CJ_COLLECTION_JSON_CONVERTER}.make)
			json.add_converter (create {CJ_DATA_JSON_CONVERTER}.make)
			j.add_converter (create {CJ_ERROR_JSON_CONVERTER}.make)
			j.add_converter (create {CJ_ITEM_JSON_CONVERTER}.make)
			j.add_converter (create {CJ_QUERY_JSON_CONVERTER}.make)
			j.add_converter (create {CJ_TEMPLATE_JSON_CONVERTER}.make)
			j.add_converter (create {CJ_LINK_JSON_CONVERTER}.make)
			if j.converter_for (create {ARRAYED_LIST [detachable ANY]}.make (0)) = Void then
				j.add_converter (create {CJ_ARRAYED_LIST_JSON_CONVERTER}.make)
			end
		end

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

feature -- Collection JSON

	build_item (req: WSF_REQUEST; user_id: INTEGER; a_graph: GRAPH; cj: CJ_COLLECTION)
		local
			cj_item: CJ_ITEM
		do
			create cj_item.make (req.absolute_script_url (user_graph_id_uri (user_id, a_graph.id)))
			cj_item.add_data (new_data ("description", a_graph.description, "Description"))
			cj_item.add_data (new_data ("content", a_graph.content, "Graph"))
			cj_item.add_data (new_data ("title", a_graph.title, "Title"))
			cj_item.add_link (new_link (req.absolute_script_url (user_graph_id_type_uri (user_id, a_graph.id, "png")), "Image", "Graph", "Title", "image/png"))
			cj_item.add_link (new_link (req.absolute_script_url (user_graph_id_type_uri (user_id, a_graph.id, "jpg")), "Image", "Graph", "Title", "image/jpg"))
			cj_item.add_link (new_link (req.absolute_script_url (user_graph_id_type_uri (user_id, a_graph.id, "pdf")), "Image", "Graph", "Title", "application/pdf"))
			cj_item.add_link (new_link (req.absolute_script_url (user_graph_id_type_uri (user_id, a_graph.id, "gif")), "Image", "Graph", "Title", "application/gif"))
			cj.add_item (cj_item)
		end

	collection_json_graph (req: WSF_REQUEST; user_id: INTEGER; g: detachable GRAPH): CJ_COLLECTION
			--	"[
			--			{
			--		   	 "collection": {
			--			   	"href": "$GRAPH_URL",
			--		        "items": [],
			--		        "links": [
			--		            {
			--		                "href": "$HOME_URL",
			--		                "prompt": "Home Graph",
			--		                "rel": "Home"
			--		            }
			--		        ],
			--		        "queries": [],
			--		        "template":{
			--		    		   "data" :
			--		       				 [
			--		        			{"name" : "title", "value" : "","prompt" :"Title"},
			--		        			{"name" : "content", "value" : "", "prompt" : "Graphviz Code"},
			--		        			{"name" : "description", "value" : "", "prompt" : "Description"}
			--		        	 ]
			--		   			},
			--		        "version": "1.0"
			--		    	}
			--			}
			--	]"
		local
			col: CJ_COLLECTION
			lnk: CJ_LINK
			tpl: CJ_TEMPLATE
			d: CJ_DATA
		do
			create col.make_with_href (req.absolute_script_url (user_id_graph_uri (user_id)))

				-- Links
			create lnk.make (req.absolute_script_url (home_uri), "Home")
			lnk.set_prompt ("Home Graph")
			col.add_link (lnk)
			create lnk.make (req.absolute_script_url (user_id_uri (user_id)), "User")
			lnk.set_prompt ("Home User")
			col.add_link (lnk)

				-- Template
			create tpl.make
			create d.make_with_name ("title");
			d.set_prompt ("Title")
			if g /= Void then
				d.set_value (g.title)
			end
			tpl.add_data (d)
			create d.make_with_name ("content");
			d.set_prompt ("Graphviz Code")
			if g /= Void then
				d.set_value (g.content)
			end
			tpl.add_data (d)
			create d.make_with_name ("description");
			d.set_prompt ("Description")
			if g /= Void then
				d.set_value (g.description)
			end
			tpl.add_data (d)
			col.set_template (tpl)
			Result := col
		end

	new_data (name: STRING_32; value: detachable STRING_32; prompt: STRING_32): CJ_DATA
		do
			create Result.make
			Result.set_name (name)
			if attached value as l_val then
				Result.set_value (l_val)
			else
				Result.set_value ("")
			end
			Result.set_prompt (prompt)
		end

	new_link (href: STRING_32; rel: STRING_32; prompt: detachable STRING_32; name: detachable STRING_32; render: detachable STRING_32): CJ_LINK
		do
			create Result.make (href, rel)
			if attached name as l_name then
				Result.set_name (l_name)
			end
			if attached render as l_render then
				Result.set_render (l_render)
			end
			if attached prompt as l_prompt then
				Result.set_prompt (l_prompt)
			end
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
