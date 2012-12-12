note
	description: "{USER_REGISTER_HANDLER} handler to register new users"
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	USER_REGISTER_HANDLER

inherit

	WSF_URI_HANDLER
		rename
			execute as uri_execute,
			new_mapping as new_uri_mapping
		end

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get,
			do_post
		end

	SHARED_EJSON

	SHARED_DATABASE_API

	REFACTORING_HELPER

	GRAPHVIZ_SERVER_URI_TEMPLATES


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

feature --HTTP Methods

	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found
		do
			if attached req.orig_path_info as orig_path then
				compute_response_get (req, res)
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			h: HTTP_HEADER
			l_msg: STRING
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			l_msg := collection_json_root (req)
			h.put_content_length (l_msg.count)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (l_msg)
		end

	do_post (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Here the convention is the following.
			-- POST is used for creation and the server determines the URI
			-- of the created resource.
			-- If the request post is SUCCESS, the server will create the user and will response with
			-- HTTP_RESPONSE 201 CREATED, the Location header will contains the newly created user's URI
			-- if the request post is not SUCCESS, the server will response with
			-- HTTP_RESPONSE 400 BAD REQUEST, the client send a bad request
			-- HTTP_RESPONSE 500 INTERNAL_SERVER_ERROR, when the server can deliver the request
		local
			l_post: STRING
			cj_error: CJ_ERROR
		do
			l_post := retrieve_data (req)
			if attached {USER} extract_cj_request (l_post) as l_user then
					-- save graph
					-- return the location uri of the USER and return a 201
					--| Here maybe we need to verify if the save action
					--| was succesful or not, if not was successfull, we need to
					--| send a 50x error.
				if not user_dao.exist_user_name (l_user.user_name) then
					user_dao.insert (l_user)
					l_user.set_id (user_dao.last_row_id.to_integer_32)
					compute_response_post (req, res, l_user)
				else
					if attached json_to_cj (collection_json_root (req)) as l_cj then
						--| if the user name already exist we send the error in the error object in the collection json.
						create cj_error.make ("User name exist", "001", "The user name " + l_user.user_name + " already exist in the system, it should be unique")
						l_cj.set_error (cj_error)
						if attached json.value (l_cj) as l_cj_answer then
							compute_response_post_error (req, res, l_cj_answer.representation)
						end
					end
				end
			else
				handle_bad_request_response (l_post + "%N is not a valid user", req, res)
			end
		end

	compute_response_post_error (req: WSF_REQUEST; res: WSF_RESPONSE; an_answer: STRING)
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

	compute_response_post (req: WSF_REQUEST; res: WSF_RESPONSE; a_user: USER)
		local
			h: HTTP_HEADER
			l_location: STRING
		do
				--| Here we send a response with status code 201 and the uri of
				--| the new resource.
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			l_location := req.absolute_script_url (user_id_uri (a_user.id))
			h.put_location (l_location)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.created)
			res.put_header_text (h.string)
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

	json_to_cj (req: STRING): detachable CJ_COLLECTION
		local
			parser: JSON_PARSER
		do
			initialize_converters (json)
			create parser.make_parser (req)
			if attached parser.parse as jv then
				if attached {CJ_COLLECTION} json.object (jv, "CJ_COLLECTION") as l_col then
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

	collection_json_root (req: WSF_REQUEST): STRING
		do
			create Result.make_from_string (collection_json_root_tpl)
			Result.replace_substring_all ("$HOME_URL", req.absolute_script_url (home_uri))
		end

	collection_json_root_tpl: STRING = "[
					{
			   	 "collection": {
			        "items": [],
			        "links": [
			           {
			                "href": "$HOME_URL",
			                "prompt": "Home Graph",
			                "rel": "Home"
			            }
			        ],
			        "queries": [],
			        "template":{
			    		   "data" :
			       				 [
			        			{"name" : "User Name", "value" : "","prompt" :"User Name"},
			        			{"name" : "Password", "value" : "", "prompt" : "Password"}
			        	 ]
			   			},
			        "version": "1.0"
			    	}
				}
		]"

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
