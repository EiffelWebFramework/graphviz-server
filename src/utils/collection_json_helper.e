note
	description: "Summary description for {COLLECTION_JSON_HELPER}."
	date: "$Date$"
	revision: "$Revision$"

class
	COLLECTION_JSON_HELPER

inherit

	GRAPHVIZ_SERVER_URI_TEMPLATES

	SHARED_EJSON

feature -- Collection + JSON

	new_error (a_title: STRING; a_code: STRING; a_message: STRING): CJ_ERROR
		local
		do
			create Result.make (a_title, a_code, a_message)
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

	new_query (href: STRING_32; rel: STRING_32; prompt: detachable STRING_32; name: detachable STRING_32; data: detachable CJ_DATA): CJ_QUERY
		do
			create Result.make (href, rel)
			if attached prompt as l_prompt then
				Result.set_prompt (l_prompt)
			end
			if attached name as l_name then
				Result.set_name (l_name)
			end
			if attached data as l_data then
				Result.add_data (l_data)
			end
		end

	json_to_cj (post: STRING): detachable CJ_COLLECTION
		local
			parser: JSON_PARSER
		do
			initialize_converters (json)
			create parser.make_parser (post)
			if attached parser.parse_object as cj and parser.is_parsed then
				if attached {CJ_COLLECTION} json.object (cj, "CJ_COLLECTION") as l_col then
					Result := l_col
				end
			end
		end

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

	collection_json_root (req: WSF_REQUEST): STRING
		do
			create Result.make_from_string (collection_json_root_tpl)
			Result.replace_substring_all ("$USER_REGISTER_URL", req.absolute_script_url (register_uri))
			Result.replace_substring_all ("$USER_LOGIN_URL", req.absolute_script_url (login_uri))
			Result.replace_substring_all ("$GRAPH_URL", req.absolute_script_url (graph_uri))
		end

	collection_json_minimal_builder (req: WSF_REQUEST): CJ_COLLECTION
		do
			create Result.make_with_href_and_version (req.absolute_script_url (req.request_uri), "1.0")
		end

	collection_json_root_builder (req: WSF_REQUEST): CJ_COLLECTION
		local
			col: CJ_COLLECTION
		do
			col := collection_json_minimal_builder (req)

				-- Links
			col.add_link (new_link (req.absolute_script_url (api_uri), "home", "Home API", Void, Void))
			col.add_link (new_link (req.absolute_script_url (graph_uri), "graphs", "Home Graph", Void, Void))
			col.add_link (new_link (req.absolute_script_url (register_uri), "register", "User Register", Void, Void))
			col.add_link (new_link (req.absolute_script_url (login_uri), "login", "User Login", Void, Void))
			col.add_query (new_query (req.absolute_script_url (queries_uri), "search", "Search by title", Void, new_data ("search", Void, "search")))
			Result := col
		end

	collection_json_root_tpl: STRING = "[
				{
			   	 "collection": {
			        "items": [],
			        "links": [
			            {
			                "href": "$USER_REGISTER_URL",
			                "prompt": "User Register",
			                "rel": "Register"
			            },
			            {
			                "href": "$USER_LOGIN_URL",
			                "prompt": "User Login",
			                "rel": "Login"
			            },
			             {
			                "href": "$GRAPH_URL",
			                "prompt": "Graph List",
			                "rel": "Graph"
			            }
			            
			        ],
			        "queries": [{
			        	"href":"$QUERIES_URL",
			        	"rel":"search",
			        	"prompt":"Search by title",
			        	"data" : [
			        			{"name":"title","value":""}
			        		]
			        	}
			        	],
			        "templates": [],
			        "version": "1.0"
			    	}
				}
		]"

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
		local
			col: CJ_COLLECTION
		do
			col := collection_json_minimal_builder (req)

				-- Links
			col.add_link (new_link (req.absolute_script_url (api_uri), "home", "Home API", Void, Void))
			col.add_link (new_link (req.absolute_script_url (register_uri), "register", "User Register", Void, Void))
			col.add_link (new_link (req.absolute_script_url (login_uri), "login", "User Login", Void, Void))
			Result := col
		end

	new_user_template (u: detachable USER): CJ_TEMPLATE
		local
			d: CJ_DATA
		do
				-- Template
			create Result.make
			create d.make_with_name ("User Name");
			d.set_prompt ("User Name")
			if u /= Void then
				d.set_value (u.user_name)
			end
			Result.add_data (d)
			create d.make_with_name ("Password");
			d.set_prompt ("Password")
			if u /= Void then
				d.set_value (u.password)
			end
			Result.add_data (d)
		end

	collection_json_user_graph (req: WSF_REQUEST; user_id: INTEGER): STRING
		do
			create Result.make_from_string (collection_json_user_graph_tpl)
			Result.replace_substring_all ("$HOME_URL", req.absolute_script_url (api_uri))
			Result.replace_substring_all ("$USER_URI", req.absolute_script_url (user_id_uri (user_id)))
			Result.replace_substring_all ("$USER_GRAPH_URI", req.absolute_script_url (user_id_graph_uri (user_id)))
		end

	collection_json_user_graph_tpl: STRING = "[
					{
			   	 "collection": {
			        "items": [],
			        "links": [
			            {
			                "href": "$HOME_URL",
			                "prompt": "Home Graph",
			                "rel": "Home"
			            },
			            {
			                "href": "$USER_URI",
			                "prompt": "User Home",
			                "rel": "User Home"
			            }, 
			            {
			                "href": "$USER_GRAPH_URI",
			                "prompt": "User Graphs",
			                "rel": "User Graphs"
			            }
			            
			        ],
			        "queries": [],
			        "templates": [],
			        "version": "1.0"
			    	}
				}
		]"

	collection_json_user_graph_builder (req: WSF_REQUEST; user_id: INTEGER; g: detachable GRAPH): CJ_COLLECTION
			--      "[
			--                      {
			--                       "collection": {
			--                              "href": "$GRAPH_URL",
			--                      "items": [],
			--                      "links": [
			--                          {
			--                              "href": "$HOME_URL",
			--                              "prompt": "Home Graph",
			--                              "rel": "Home"
			--                          }
			--                      ],
			--                      "queries": [],
			--                      "template":{
			--                                 "data" :
			--                                               [
			--                                              {"name" : "title", "value" : "","prompt" :"Title"},
			--                                              {"name" : "content", "value" : "", "prompt" : "Graphviz Code"},
			--                                              {"name" : "description", "value" : "", "prompt" : "Description"}
			--                               ]
			--                                      },
			--                      "version": "1.0"
			--                      }
			--                      }
			--      ]"
		local
			col: CJ_COLLECTION
			lnk: CJ_LINK
			tpl: CJ_TEMPLATE
			d: CJ_DATA
		do
			create col.make_with_href (req.absolute_script_url (user_id_graph_uri (user_id)))

				-- Links
			create lnk.make (req.absolute_script_url (api_uri), "Home")
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

	build_item_user (req: WSF_REQUEST; user_id: INTEGER; a_graph: GRAPH; cj: CJ_COLLECTION)
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

end
