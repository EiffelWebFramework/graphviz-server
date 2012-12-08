note
	description: "Graphviz server"
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPHVIZ_SERVER

inherit

	ANY

	WSF_FILTERED_SERVICE

	WSF_HANDLER_HELPER

	WSF_DEFAULT_SERVICE

	GRAPHVIZ_SERVER_URI_TEMPLATES

	PROCESS_HELPER

create
	make

feature {NONE} -- Initialization

	make
		local
		do
			initialize_filter
			initialize_graphviz
			create {WSF_SERVICE_LAUNCHER_OPTIONS_FROM_INI} service_options.make_from_file ("server.ini")
			make_and_launch
		end

	create_filter
			--option1
		local
			router: WSF_ROUTER
			render_handler: RENDER_HANDLER
			root_handler: ROOT_HANDLER
			graph_handler: GRAPH_HANDLER
			user_register_handler: USER_REGISTER_HANDLER
			user_login_handler: USER_LOGIN_HANDLER
			user_graph_handler: USER_GRAPH_HANDLER
			user_handler: USER_HANDLER
			user_login_authentication_filter: AUTHENTICATION_FILTER
			user_authentication_filter: AUTHENTICATION_FILTER
			user_graph_authentication_filter: AUTHENTICATION_FILTER
			l_routing_filter: WSF_ROUTING_FILTER
		do
			create router.make (10)
			create root_handler
			create render_handler.make
			create user_register_handler.make
			create user_graph_handler.make
			create user_login_handler.make
			create user_handler.make
			create graph_handler.make

				-- user login authentication filter
			create user_login_authentication_filter
			user_login_authentication_filter.set_next (user_login_handler)

				-- user authentication filter
			create user_authentication_filter
			user_authentication_filter.set_next (user_handler)

				-- user graph authentication filter
			create user_graph_authentication_filter
			user_graph_authentication_filter.set_next (user_graph_handler)

				-- the uri templates that we have here are opaque, only for API developer.
				-- the client should don't take care of it

				-- root
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make ("/", root_handler), router.methods_GET)

				-- register a user
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make_trailing_slash_ignored (user_register_uri, user_register_handler), router.methods_GET_POST)

				-- login a user
			router.handle_with_request_methods (user_login_uri, user_login_authentication_filter, router.methods_GET_POST)

				--| Weird behavior the order of handler affect the selection
				--|/graph/{id} should be handled by graph
				--|/graph/{id}.{type} should be handled by render
				--| but if we put first the graph handler the last uri template also will be handled by graph handler.

				--graph
				--			router.map_with_request_methods (create {WSF_URI_MAPPING}.make_trailing_slash_ignored (graph_uri, graph_handler), router.methods_GET)
				--			router.map_with_request_methods (create {WSF_URI_TEMPLATE_MAPPING}.make_from_template (graph_id_uri_template, graph_handler), router.methods_GET)

				--render handler
			router.map_with_request_methods (create {WSF_URI_TEMPLATE_MAPPING}.make_from_template (graph_id_type_uri_template, render_handler), router.methods_GET)
			router.map_with_request_methods (create {WSF_URI_TEMPLATE_MAPPING}.make_from_template (user_graph_id_type_uri_template, render_handler), router.methods_GET)

				--graph
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make_trailing_slash_ignored (graph_uri, graph_handler), router.methods_GET)
			router.map_with_request_methods (create {WSF_URI_TEMPLATE_MAPPING}.make_from_template (graph_id_uri_template, graph_handler), router.methods_GET)

				--user
			router.handle_with_request_methods (user_id_uri_template.template, user_authentication_filter, router.methods_GET)

				-- user_graph handler
			router.handle_with_request_methods (user_graph_uri.template, user_graph_authentication_filter, router.methods_GET_POST)
			router.handle_with_request_methods (user_graph_id_uri_template.template, user_graph_authentication_filter, router.methods_GET_PUT_DELETE)
			create l_routing_filter.make (router)
			l_routing_filter.set_execute_default_action (agent execute_default)
			filter := l_routing_filter
		end

	setup_filter
			-- Setup `filter'
		local
			l_logging_filter: WSF_LOGGING_FILTER
		do
			create l_logging_filter
			filter.set_next (l_logging_filter)
		end

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
		do
			filter.execute (req, res)
		end

	execute_default (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- I'm using this method to handle the method not allowed response
			-- in the case that the given uri does not have a corresponding http method
			-- to handle it.
		local
			h: HTTP_HEADER
			l_description: STRING
		do
			if req.content_length_value > 0 then
				req.input.read_string (req.content_length_value.as_integer_32)
			end
			create h.make
			h.put_content_type_text_plain
			l_description := req.request_method + req.request_uri + " is not allowed" + "%N"
			h.put_content_length (l_description.count)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.method_not_allowed)
			res.put_header_text (h.string)
			res.put_string (l_description)
		end

	initialize_graphviz
		local
			u: GRAPHVIZ_UTILITIES
			fmts: GRAPHVIZ_FORMATS
		do
			create u
			u.set_logger (create {FILE_LOGGER}.make (io.error))
			if attached u.supported_formats as lst and then not lst.is_empty then
				create fmts
				fmts.set_supported_formats (lst)
			end
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
		Eiffel Software
		5949 Hollister Ave., Goleta, CA 93117 USA
		Telephone 805-685-1006, Fax 805-685-6869
		Website http://www.eiffel.com
		Customer support http://support.eiffel.com
	]"

end
