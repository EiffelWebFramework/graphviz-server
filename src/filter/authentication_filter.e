note
	description: "Authentication filter."
	author: "Olivier Ligot"
	date: "$Date$"
	revision: "$Revision$"

class
	AUTHENTICATION_FILTER

inherit

	WSF_FILTER_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	WSF_URI_TEMPLATE_CONTEXT_HANDLER [FILTER_HANDLER_CONTEXT]

	COLLECTION_JSON_HELPER

	SHARED_DATABASE_API

feature -- Basic operations

	execute (ctx: FILTER_HANDLER_CONTEXT; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute the filter
		local
			l_auth: HTTP_AUTHORIZATION
			l_cj : CJ_COLLECTION
		do
			create l_auth.make (req.http_authorization)
			if (attached l_auth.type as l_auth_type and then l_auth_type.is_equal ("basic")) and
			    attached l_auth.login as l_auth_login and then attached l_auth.password as l_auth_password
			    and then attached {USER} user_dao.retrieve_by_name_and_password (l_auth_login, l_auth_password) as l_user then
				ctx.set_user (l_user)
				execute_next (ctx, req, res)
			else
				initialize_converters (json)
			    l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Unauthorized", "004", "The credentials are not valid"))
				if attached json.value (l_cj) as l_cj_answer then
					handle_unauthorized (l_cj_answer.representation, req , res)
				end
			end
		end

feature {NONE} -- Implementation

	handle_unauthorized (a_description: STRING; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle forbidden.
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			h.put_content_length (a_description.count)
			h.put_current_date
			h.put_header_key_value ({HTTP_HEADER_NAMES}.header_www_authenticate, "Basic realm=%"User%"")
			res.set_status_code ({HTTP_STATUS_CODE}.unauthorized)
			res.put_header_text (h.string)
			res.put_string (a_description)
		end

note
	copyright: "2011-2012, Olivier Ligot, Jocelyn Fiat and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
