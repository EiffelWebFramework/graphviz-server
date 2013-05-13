note
	description: "Summary description for {TEST_GRAPHVIZ_SERVER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_GRAPHVIZ_SERVER
inherit
	EQA_TEST_SET
		redefine
			on_prepare,
			on_clean
		end

	GRAPHVIZ_SERVER
		undefine
			default_create
		end

feature {NONE} -- Events

	web_app: detachable NINO_SERVICE

	port_number: INTEGER
	base_url: detachable STRING

	on_prepare
			-- <Precursor>
		local
			app: NINO_SERVICE
			wt: WORKER_THREAD
			e: EXECUTION_ENVIRONMENT
		do
			create e
			initialize_router
			initialize_filter
			initialize_graphviz
			
			if port_number = 0 then
				server_log ("== Current directory: " + e.current_working_directory)

				port_number := 0
				base_url := ""
				create app.make_custom (to_wgi_service, base_url)
				web_app := app

				create wt.make (agent app.listen (port_number))
				wt.launch
				e.sleep (1_000_000_000 * 5)
				port_number := app.port
				server_log ("Server port=" + port_number.out)
			else
				server_log ("Use existing server")
				server_log ("== Current directory: " + e.current_working_directory)

			end
		end

	server_log_name: STRING
		local
			fn: FILE_NAME
		once
			create fn.make_from_string ("./server_test.log")
			Result := fn.string
		end

	server_log (m: STRING_8)
		local
			f: RAW_FILE
		do
			create f.make_open_append (server_log_name)--"..\server-tests.log")
			f.put_string (m)
			f.put_character ('%N')
			f.close
		end

	on_clean
			-- <Precursor>
		do
			if attached web_app as app then
				app.shutdown
			end
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
