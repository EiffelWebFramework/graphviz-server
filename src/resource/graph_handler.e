note
	description: "GRAPH_HANDLER handle the graph resources, it allow create, get one or all, delete and updates graphs"
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
			do_get,
			do_post,
			do_put,
			do_delete
		end

	SHARED_EJSON

	GRAPH_MANAGER

	REFACTORING_HELPER

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
			-- 404 Resource not found
		local
			cj_error: CJ_ERROR
		do
				--| TODO refactor code.
				--| GET need to handle two different kind of request now.
				--| The first case, /graph, mean retrieve all graphs
				--| The second case, /graph/{id} with the path parametrer id,
				--| in this case retrive the graph with the given id.
				--| Maybe the first case need to be refactored and removed to a new
				--| handler possibly the SEARCH_HANLDER.
			if attached req.orig_path_info as orig_path then
				if attached get_graph_id_from_path (orig_path) as l_id then
						-- retrieve a graph identidied by l_id
					if attached retrieve_by_id (l_id.to_integer_32) as l_graph then
						if attached json_to_cj (req) as l_cj then
							build_item (req, l_graph, l_cj)
							if attached {JSON_VALUE} json.value (l_cj) as l_cj_answer then
								compute_response_get (req, res, l_cj_answer.representation)
							end
						end
					else
						if attached json_to_cj (req) as l_cj then
							create cj_error.make ("Resource not found", "001", "The graph id " + l_id.out + " does not exist in the system")
							l_cj.set_error (cj_error)
							if attached {JSON_VALUE} json.value (l_cj) as l_cj_answer then
								handle_resource_not_found_response (l_cj_answer.representation, req, res)
							end
						end
					end
				else
						-- retrieve all
					if attached retrieve_all as graphs then
						if attached json_to_cj (req) as l_cj then
							across
								graphs as ic
							loop
								build_item (req, ic.item, l_cj)
							end
							if attached {JSON_VALUE} json.value (l_cj) as l_cj_answer then
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
				h.add_header ("Date:" + time.formatted_out ("ddd,[0]dd mmm yyyy [0]hh:[0]mi:[0]ss.ff2") + " GMT")
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (l_msg)
		end

	do_post (req: WSF_REQUEST; res: WSF_RESPONSE)
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
		do
			l_post := retrieve_data (req)
			if attached extract_cj_request (l_post) as l_graph then
					-- save graph
					-- return the location uri of the graph and return a 201
					--| Here maybe we need to verify if the save action in
					--| was succesful or not, if not was successfull, we need to
					--| send a 50x error.
				insert (l_graph)
				l_graph.set_id (last_row_id.to_integer_32)
				compute_response_post (req, res, l_graph)
			else
				handle_bad_request_response (l_post + "%N is not a valid Graph", req, res)
			end
		end

	compute_response_post (req: WSF_REQUEST; res: WSF_RESPONSE; a_graph: GRAPH)
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
			if attached req.http_host as host then
				l_location := "http://" + host + req.request_uri + "/" + a_graph.id.out
				h.put_location (l_location)
			end
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.created)
			res.put_header_text (h.string)
		end

	do_delete (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Here we use DELETE to cancel a graph description.
			-- 200 if is ok
			-- 404 Resource not found
			-- 500 if we have an internal server error
		do
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("id") as l_id then
					delete_by_id (l_id.value.to_integer_32)
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

	do_put (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Updating a resource with PUT
			-- A successful PUT request will not create a new resource, instead it will
			-- change the state of the resource identified by the current uri.
			-- If success we response with 200.
			-- 404 if the graph is not found
			-- 400 in case of a bad request
			-- 500 internal server error
		local
			l_put: STRING
		do
			l_put := retrieve_data (req)
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("id") as l_id then
					if attached extract_cj_request (l_put) as lreq_graph and then attached retrieve_by_id (l_id.value.to_integer_32) as ldb_graph then
						ldb_graph.set_description (lreq_graph.description)
						ldb_graph.set_title (lreq_graph.title)
						ldb_graph.set_content (lreq_graph.content)
						update (ldb_graph)
						compute_response_put (req, res)
					else
						handle_resource_not_found_response ("The resource " + l_id.value + " was not found ", req, res)
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
					if ic.item.name ~ "title" then
						l_title := ic.item.value
					end
					if ic.item.name ~ "description" then
						l_description := ic.item.value
					end
					if ic.item.name ~ "content" then
						l_content := ic.item.value
					end
				end
				if attached l_content as lc then
					create Result.make (lc, l_title, l_description)
				end
			end
		end

	json_to_cj (req: WSF_REQUEST): detachable CJ_COLLECTION
		local
			parser: JSON_PARSER
		do
			initialize_converters (json)
			create parser.make_parser (collection_json_graph (req))
			if attached parser.parse as jv then
				if attached {CJ_COLLECTION} json.object (jv, "CJ_COLLECTION") as l_col then
					Result := l_col
				end
			end
		end

feature -- Collection JSON

	build_item (req: WSF_REQUEST; a_graph: GRAPH; cj: CJ_COLLECTION)
		local
			cj_item: CJ_ITEM
		do
			create cj_item.make (req.absolute_script_url ("/graph/" + a_graph.id.out))
			cj_item.add_data (new_data ("description", a_graph.description, "Description"))
			cj_item.add_data (new_data ("content", a_graph.content, "Grahp"))
			cj_item.add_data (new_data ("title", a_graph.title, "Title"))
			cj_item.add_link (new_link (req.absolute_script_url ("/graph/" + a_graph.id.out + "/render;jpg"), "Image", "Graph", "Title", "image/jpg"))
			cj_item.add_link (new_link (req.absolute_script_url ("/graph/" + a_graph.id.out + "/render;pdf"), "Image", "Graph", "Title", "application/pdf"))
			cj_item.add_link (new_link (req.absolute_script_url ("/graph/" + a_graph.id.out + "/render;gif"), "Image", "Graph", "Title", "application/gif"))
			cj.add_item (cj_item)
		end

	collection_json_graph (req: WSF_REQUEST): STRING
		do
			create Result.make_from_string (collection_json_graph_tpl)
			if attached req.http_host as l_host then
				Result.replace_substring_all ("$ROOT_URL", "http://" + l_host)
			else
				Result.replace_substring_all ("$ROOT_URL", "")
			end
		end

	collection_json_graph_tpl: STRING = "[
				{
			   	 "collection": {
				   	"href": "$ROOT_URL/graph",
			        "items": [],
			        "links": [
			            {
			                "href": "$ROOT_URL/",
			                "prompt": "Home Graph",
			                "rel": "Home"
			            }
			        ],
			        "queries": [],
			        "template":{
			    		   "data" :
			       				 [
			        			{"name" : "title", "value" : "","prompt" :"Title"},
			        			{"name" : "content", "value" : "", "prompt" : "Graphviz Code"},
			        			{"name" : "description", "value" : "", "prompt" : "Description"}
			        	 ]
			   			},
			        "version": "1.0"
			    	}
				}
		]"

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

feature -- URI Utils

	get_graph_id_from_path (a_path: READABLE_STRING_32): detachable STRING
		local
			l_list: LIST [READABLE_STRING_32]
		do
			l_list := a_path.split ('/')
			if l_list.valid_index (3) then
				Result := l_list.at (3)
			end
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
