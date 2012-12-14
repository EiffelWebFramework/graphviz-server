note
	description: "Summary description for {USER_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	USER_HANDLER

inherit

	WSF_FILTER_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	WSF_URI_TEMPLATE_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	WSF_RESOURCE_CONTEXT_HANDLER_HELPER [FILTER_HANDLER_CONTEXT]
		redefine
			do_get
		end

	COLLECTION_JSON_HELPER

	SHARED_DATABASE_API

	REFACTORING_HELPER

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
		require else
			authenticated_user_attached: attached ctx.user
		local
			l_cj: CJ_COLLECTION
		do
				--| TODO refactor code.
			initialize_converters (json)
			if attached {WSF_STRING} req.path_parameter ("id") as l_id and then l_id.is_integer and then attached ctx.user as auth_user and then attached user_dao.retrieve_by_id (l_id.integer_value) as l_user then
				if l_user.id = auth_user.id then
					if attached json_to_cj (collection_json_user_graph (req, l_user.id)) as cj then
						if attached json.value (cj) as l_cj_answer then
							compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.ok)
						end
					end
				elseif attached ctx.user as l_auth_user then
						-- Trying to access another user that the authenticated one,
						-- which is forbidden in this example...
					l_cj := collection_json_root_builder (req)
					l_cj.set_error (new_error ("Fobidden", "003", "You try to access the user " + l_id.value + " while authenticating with the user " + l_auth_user.id.out))
					if attached json.value (l_cj) as l_cj_answer then
						compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.forbidden)
					end
				end
			else
				l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Resource Not found", "001", "You try to access the user " + req.request_uri + " and it does not exist in the system"))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
				end
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; msg: STRING; status_code: INTEGER)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			h.put_content_length (msg.count)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code (status_code)
			res.put_header_text (h.string)
			res.put_string (msg)
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
