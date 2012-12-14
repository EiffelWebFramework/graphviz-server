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


	SHARED_DATABASE_API

	REFACTORING_HELPER

	COLLECTION_JSON_HELPER


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

	compute_response (req: WSF_REQUEST; res: WSF_RESPONSE; msg: STRING; status_code: INTEGER)
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
			l_cj : CJ_COLLECTION
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
					l_cj := collection_json_root_builder (req)
					--| if the user name already exist we send the error in the error object in the collection json.
					l_cj.set_error (new_error ("User name exist", "001", "The user name " + l_user.user_name + " already exist in the system, it should be unique"))
					if attached json.value (l_cj) as l_cj_answer then
						compute_response (req, res, l_cj_answer.representation,{HTTP_STATUS_CODE}.conflict)
					end

				end
			else
				l_cj := collection_json_root_builder (req)
				--| if the user name already exist we send the error in the error object in the collection json.
				l_cj.set_error (new_error ("Bad request", "004", "The template : "+ l_post + " is not valid"  ))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation,{HTTP_STATUS_CODE}.bad_request)
				end
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



note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
