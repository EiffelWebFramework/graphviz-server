note
	description: "{USER_LOGIN_HANDLER} handler to authenticate a user"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	USER_LOGIN_HANDLER

inherit

	WSF_FILTER_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	WSF_URI_TEMPLATE_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	WSF_RESOURCE_CONTEXT_HANDLER_HELPER [FILTER_HANDLER_CONTEXT]
		redefine
			do_get
		end

	SHARED_EJSON

	SHARED_DATABASE_API

	REFACTORING_HELPER

	GRAPHVIZ_SERVER_URI_TEMPLATES

feature -- execute

	execute (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (ctx, req, res)
			execute_next (ctx, req, res)
		end

feature --HTTP Methods

	do_get (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			--| Maybe in this case is better to use URI_templates and send a GET request

			-- Here the convention is the following.
			-- If the request is SUCCESS, the server will response with the possible states that a
			-- a valid user could do HTTP_RESPONSE 200 OK
			-- if the request is not SUCCESS, the server will response with
			-- HTTP_RESPONSE 400 BAD REQUEST, the client send a bad request (maybe the user and password are wrong)
			-- and will response with a cj with a corresponding Error.
			-- HTTP_RESPONSE 500 INTERNAL_SERVER_ERROR, when the server can deliver the request
		local
			cj_error: CJ_ERROR
		do
			if attached {USER} ctx.user as l_user then
				if attached {USER} user_dao.retrieve_by_name_and_password (l_user.user_name, l_user.password) as a_user then
					compute_response_get (req, res, a_user)
				else
					if attached json_to_cj (collection_json_user (req, 0)) as l_cj then
						create cj_error.make ("User name does not exist or the password is wrong", "002", "The user name " + l_user.user_name + " not exist in the system or the password was wrong, try again")
						l_cj.set_error (cj_error)
						if attached json.value (l_cj) as l_cj_answer then
							compute_response_get_error (req, res, l_cj_answer.representation)
						end
					end
				end
			else
				handle_bad_request_response ("%N Is not a valid user", req, res)
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; a_user: USER)
		local
			h: HTTP_HEADER
			l_msg: STRING
		do
				--| Here we send a response with status code 200
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			l_msg := collection_json_user (req, a_user.id)
			h.put_content_length (l_msg.count)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (l_msg)
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

feature -- Collection JSON support

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

	extract_cj_request (l_post: STRING): detachable USER
			-- extract an object User from the request, or Void
			-- if the request is invalid
		local
			l_user_name: detachable STRING_32
			l_password: detachable STRING_32
		do
			if attached json_to_cj_template (l_post) as template then
				across
					template.data as ic
				loop
					if ic.item.name ~ "User Name" then
						l_user_name := ic.item.value
					end
					if ic.item.name ~ "Password" then
						l_password := ic.item.value
					end
				end
				if attached l_user_name as l_usr_n and then attached l_password as l_pwd then
					create Result.make (l_usr_n, l_pwd)
				end
			end
		end

	collection_json_user (req: WSF_REQUEST; user_id: INTEGER): STRING
		do
			create Result.make_from_string (collection_json_user_tpl)
			Result.replace_substring_all ("$HOME_URL", req.absolute_script_url (home_uri))
			Result.replace_substring_all ("$USER_URI", req.absolute_script_url (user_id_uri (user_id)))
			Result.replace_substring_all ("$GRAPH_URI", req.absolute_script_url (graph_uri))
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
			            },
			               {
			                "href": "$GRAPH_URI",
			                "prompt": "Graphs ",
			                "rel": "List of graphs"
			            }
			        ],
			        "queries": [],
			        "templates": [],
			        "version": "1.0"
			    	}
				}
		]"

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
