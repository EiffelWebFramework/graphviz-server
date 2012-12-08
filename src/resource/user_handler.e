note
	description: "Summary description for {USER_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	USER_HANDLER

inherit

	WSF_FILTER_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]
		select
			default_create
		end

	WSF_URI_TEMPLATE_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	WSF_RESOURCE_CONTEXT_HANDLER_HELPER [FILTER_HANDLER_CONTEXT]
		redefine
			do_get
		end

	SHARED_EJSON

	GRAPHVIZ_SERVER_URI_TEMPLATES

	USER_MANAGER
		rename
			default_create as urm_default_create
		end

	REFACTORING_HELPER

create
	make

feature -- Initialization

	make
		do
			urm_default_create
		end

feature -- execute

	execute (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (ctx, req, res)
			execute_next (ctx, req, res)
		end

feature -- HTTP Methods

		--| Right now conditional GET and PUT are not implemented.

	do_get (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found
		local
			cj_error: CJ_ERROR
			l_credentials: TUPLE [user: STRING; password: STRING]
		do
				--| TODO refactor code.
			initialize_converters (json)
			if attached req.http_authorization as http_authorization and then attached {WSF_STRING} req.path_parameter ("id") as l_id and then l_id.is_integer then
				l_credentials := retieve_credentials (http_authorization)
				if attached {USER} retrieve_by_name_and_password (l_credentials.user, l_credentials.password) as a_user then
					compute_response_get (req, res, a_user)
				else
					if attached json_to_cj (collection_json_user (req, l_id.integer_value)) as l_cj then
						create cj_error.make ("User name does not exist or the password is wrong", "002", "The user name " + l_credentials.user + " not exist in the system or the password was wrong, try again")
						l_cj.set_error (cj_error)
						if attached json.value (l_cj) as l_cj_answer then
							compute_response_get_error (req, res, l_cj_answer.representation)
						end
					end
				end
			else
				handle_basic_authentication_error (req, res, "Graphviz")
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; a_user: USER)
		local
			h: HTTP_HEADER
			l_msg: STRING
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			if attached json_to_cj (collection_json_user_graph (req, a_user.id)) as l_cj then
				if attached json.value (l_cj) as l_cj_answer then
					l_msg := l_cj_answer.representation
					h.put_content_length (l_msg.count)
					if attached req.request_time as time then
						h.put_utc_date (time)
					end
					res.set_status_code ({HTTP_STATUS_CODE}.ok)
					res.put_header_text (h.string)
					res.put_string (l_msg)
				end
			end
		end

	compute_response_get_error (req: WSF_REQUEST; res: WSF_RESPONSE; an_answer: STRING)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			h.put_content_length (an_answer.count)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
			res.put_header_text (h.string)
			res.put_string (an_answer)
		end

feature {NONE} -- Implementacion Repository and Graph Layer

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

	collection_json_user_graph (req: WSF_REQUEST; user_id: INTEGER): STRING
		do
			create Result.make_from_string (collection_json_user_graph_tpl)
			Result.replace_substring_all ("$HOME_URL", req.absolute_script_url (home_uri))
			Result.replace_substring_all ("$USER_URI", req.absolute_script_url (user_id_uri (user_id)))
			Result.replace_substring_all ("$USER_GRAPH_URI", req.absolute_script_url (user_id_graph_uri (user_id)))
		end

	collection_json_user (req: WSF_REQUEST; user_id: INTEGER): STRING
		do
			create Result.make_from_string (collection_json_user_tpl)
			Result.replace_substring_all ("$HOME_URL", req.absolute_script_url (home_uri))
			Result.replace_substring_all ("$USER_URI", req.absolute_script_url (user_id_uri (user_id)))
		end

	collection_json_user_tpl: STRING = "[
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
			            }
			        ],
			        "queries": [],
			        "templates": [],
			        "version": "1.0"
			    	}
				}
		]"

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

feature -- Collection JSON

feature -- Basic Authentication

	retieve_credentials (http_authorization: READABLE_STRING_8): TUPLE [user: STRING; password: STRING]
		local
			l_list: LIST [READABLE_STRING_8]
			l_cred: LIST [READABLE_STRING_8]
			decode: BASE64
			l_secret: STRING
		do
			l_list := http_authorization.split (' ')
			check
				l_list.count = 2
				l_list.at (1) ~ "Basic"
			end
			create decode
			l_secret := decode.decoded_string (l_list.at (2))
			l_cred := l_secret.split (':')
			create Result
			Result.put (l_cred.at (1), 1)
			Result.put (l_cred.at (2), 2)
		end

	handle_basic_authentication_error (req: WSF_REQUEST; res: WSF_RESPONSE; realm: STRING)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_current_date
			h.add_header_key_value ("WWW-Authenticate", "Basic realm= %"" + realm + "%"")
			res.set_status_code ({HTTP_STATUS_CODE}.unauthorized)
			res.put_header_text (h.string)
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
