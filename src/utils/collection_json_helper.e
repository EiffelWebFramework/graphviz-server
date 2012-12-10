note
	description: "Summary description for {COLLECTION_JSON_HELPER}."
	author: ""
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
			Result.replace_substring_all ("$USER_REGISTER_URL", req.absolute_script_url (user_register_uri))
			Result.replace_substring_all ("$USER_LOGIN_URL", req.absolute_script_url (user_login_uri))
			Result.replace_substring_all ("$GRAPH_URL", req.absolute_script_url (graph_uri))
		end

	collection_json_root_builder (req: WSF_REQUEST): CJ_COLLECTION
			--	{
			--			   	 "collection": {
			--			        "items": [],
			--			        "links": [
			--			            {
			--			                "href": "$USER_REGISTER_URL",
			--			                "prompt": "User Register",
			--			                "rel": "Register"
			--			            },
			--			            {
			--			                "href": "$USER_LOGIN_URL",
			--			                "prompt": "User Login",
			--			                "rel": "Login"
			--			            },
			--			             {
			--			                "href": "$GRAPH_URL",
			--			                "prompt": "Graph List",
			--			                "rel": "Graph"
			--			            }
			--
			--			        ],
			--			        "queries": [],
			--			        "templates": [],
			--			        "version": "1.0"
			--			    	}
			--				}
			--		]"

		local
			col: CJ_COLLECTION
			lnk: CJ_LINK
			tpl: CJ_TEMPLATE
			d: CJ_DATA
		do
			create col.make_with_href_and_version (req.absolute_script_url (req.request_uri), "1.0")

				-- Links
			create lnk.make (req.absolute_script_url (home_uri), "Home")
			lnk.set_prompt ("Home Graph")
			lnk.set_rel ("home")
			col.add_link (lnk)
			create lnk.make (req.absolute_script_url (user_register_uri), "User Register")
			lnk.set_prompt ("User Register")
			lnk.set_rel("register")
			col.add_link (lnk)
			create lnk.make (req.absolute_script_url (user_login_uri), "User Login")
			lnk.set_prompt ("User Login")
			lnk.set_rel("login")
			col.add_link (lnk)

				-- Template
			create tpl.make
			create d.make_with_name ("title");
			d.set_prompt ("Title")
			tpl.add_data (d)
			create d.make_with_name ("content");
			d.set_prompt ("Graphviz Code")
			tpl.add_data (d)
			create d.make_with_name ("description");
			d.set_prompt ("Description")
			tpl.add_data (d)
			col.set_template (tpl)
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
			        "queries": [],
			        "templates": [],
			        "version": "1.0"
			    	}
				}
		]"

end
