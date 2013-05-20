note
	description: "Summary description for {GRAPHVIZ_SERVER_LAUNCH_TEST}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPHVIZ_SERVER_LAUNCH_TEST
inherit
	EQA_TEST_SET
		redefine
			on_prepare,
			on_clean
		end
	SERVER_TEST
		undefine
			default_create
		end
feature {NONE} -- Events


	on_prepare
			-- <Precursor>
		do
			make
		end

	on_clean
			-- <Precursor>
		do
			shutdown
		end

	http_session: detachable HTTP_CLIENT_SESSION

	get_http_session
		local
			h: LIBCURL_HTTP_CLIENT
			b: like base_url
		do
			create h.make
			b := base_url
			if b = Void then
				b := ""
			end
			if attached {HTTP_CLIENT_SESSION} h.new_session ("localhost:" + port_number.out + "/" + b) as sess then
				http_session := sess
				sess.set_timeout (-1)
				sess.set_is_debug (True)
				sess.set_connect_timeout (-1)
--				sess.set_proxy ("127.0.0.1", 8888) --| inspect traffic with http://www.fiddler2.com/								
			end
		end

	adapted_context (ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): HTTP_CLIENT_REQUEST_CONTEXT
		do
			if ctx /= Void then
				Result := ctx
			else
				create Result.make
			end
--			Result.set_proxy ("127.0.0.1", 8888) --| inspect traffic with http://www.fiddler2.com/			
		end

feature -- Test routines

	test_get_home
			-- New test routine
		do
			if attached execute_get ("") as l_resp then
				assert("Expected status 200", l_resp.status = 200)
			end
		end

	test_post_home_not_allowed
			-- New test routine
		do
			if attached execute_post ("",Void) as l_resp then
				assert("Expected status 405", l_resp.status = 405)
			end
		end


feature -- HTTP client helpers
	execute_get (command_name: STRING_32): detachable HTTP_CLIENT_RESPONSE
		do
			get_http_session
			if attached http_session as sess then
				Result := sess.get (command_name, context_executor)
			end
		end

	execute_post (command_name: STRING_32; data: detachable READABLE_STRING_8): detachable HTTP_CLIENT_RESPONSE
		do
			get_http_session
			if attached http_session as sess then
				Result := sess.post (command_name, context_executor, data)
			end
		end

	execute_delete (command_name: STRING_32): detachable HTTP_CLIENT_RESPONSE
		do
			get_http_session
			if attached http_session as sess then
				Result := sess.delete (command_name, context_executor)
			end
		end

	execute_put (command_name: STRING_32; data: detachable READABLE_STRING_8): detachable HTTP_CLIENT_RESPONSE
		do
			get_http_session
			if attached http_session as sess then
				Result := sess.put (command_name, context_executor, data)
			end
		end

	context_executor: HTTP_CLIENT_REQUEST_CONTEXT
			-- request context for each request
		do
			create Result.make
			Result.headers.put ("application/vnd.collection+json", "Content-Type")
			Result.headers.put ("application/vnd.collection+json", "Accept")
		end



end
