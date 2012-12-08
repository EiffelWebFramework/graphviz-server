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
		select
			default_create
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
			initialize_converters (json)

			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("id") as l_id and then l_id.is_integer  then
						-- retrieve a graph identidied by l_id
					if attached retrieve_by_id (l_id.integer_value) as l_graph then
						if attached collection_json_graph (req, l_graph) as l_cj then
							build_item (req, l_graph, l_cj)
							if attached json.value (l_cj) as l_cj_answer then
								compute_response_get (req, res, l_cj_answer.representation)
							end
						end
					else
						if attached collection_json_graph (req, Void) as l_cj then
							create cj_error.make ("Resource not found", "001", "The graph id " + l_id.out + " does not exist in the system")
							l_cj.set_error (cj_error)
							if attached json.value (l_cj) as l_cj_answer then
								handle_resource_not_found_response (l_cj_answer.representation, req, res)
							end
						end
					end
				else
						-- retrieve all
					if attached retrieve_all as graphs then
						if attached collection_json_graph (req, Void) as l_cj then
							across
								graphs as ic
							loop
								build_item (req, ic.item, l_cj)
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

	build_item (req: WSF_REQUEST; a_graph: GRAPH; cj: CJ_COLLECTION)
		local
			cj_item: CJ_ITEM
		do
			create cj_item.make (req.absolute_script_url (graph_id_uri (a_graph.id)))
			cj_item.add_data (new_data ("description", a_graph.description, "Description"))
			cj_item.add_data (new_data ("content", a_graph.content, "Graph"))
			cj_item.add_data (new_data ("title", a_graph.title, "Title"))
			cj_item.add_link (new_link (req.absolute_script_url (graph_id_type_uri (a_graph.id, "png")), "Image", "Graph", "Title", "image/png"))
			cj_item.add_link (new_link (req.absolute_script_url (graph_id_type_uri (a_graph.id, "jpg")), "Image", "Graph", "Title", "image/jpg"))
			cj_item.add_link (new_link (req.absolute_script_url (graph_id_type_uri (a_graph.id, "pdf")), "Image", "Graph", "Title", "application/pdf"))
			cj_item.add_link (new_link (req.absolute_script_url (graph_id_type_uri (a_graph.id, "gif")), "Image", "Graph", "Title", "application/gif"))
			cj.add_item (cj_item)
		end

	collection_json_graph (req: WSF_REQUEST; g: detachable GRAPH): CJ_COLLECTION
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
			create col.make_with_href (req.absolute_script_url (graph_uri))

			-- Links
			create lnk.make (req.absolute_script_url (home_uri), "Home")
			lnk.set_prompt ("Home Graph")
			col.add_link (lnk)


			-- Template
			create tpl.make
			create d.make_with_name ("title"); d.set_prompt ("Title")
			if g /= Void then
				d.set_value (g.title)
			end
			tpl.add_data (d)

			create d.make_with_name ("content"); d.set_prompt ("Graphviz Code")
			if g /= Void then
				d.set_value (g.content)
			end
			tpl.add_data (d)

			create d.make_with_name ("description"); d.set_prompt ("Description")
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
