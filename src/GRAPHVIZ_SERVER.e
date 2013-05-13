note
	description: "Graphviz server"
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPHVIZ_SERVER

inherit

	WSF_DEFAULT_SERVICE

	WSF_FILTERED_SERVICE
		redefine
			execute
		end

	WSF_ROUTED_SERVICE
		rename
			execute as execute_router
		redefine
			execute_default
		end

	WSF_FILTER
		rename
			execute as execute_router
		end

	WSF_HANDLER_HELPER

	COLLECTION_JSON_HELPER

	PROCESS_HELPER

create
	make

feature {NONE} -- Initialization

	make
		do
			initialize_router
			initialize_filter
			initialize_graphviz
			create {WSF_SERVICE_LAUNCHER_OPTIONS_FROM_INI} service_options.make_from_file ("server.ini")
			make_and_launch
		end

	create_filter
			-- Create `filter'
		do
			create {WSF_LOGGING_FILTER} filter
		end

	setup_router
		local
			l_options_filter: WSF_CORS_OPTIONS_FILTER

			user_login_authentication_filter,
			user_authentication_filter,
			user_graph_authentication_filter: AUTHENTICATION_FILTER

			render_handler: RENDER_HANDLER
			root_handler: ROOT_HANDLER
			graph_handler: GRAPH_HANDLER
			register_handler: USER_REGISTER_HANDLER
			login_handler: USER_LOGIN_HANDLER
			user_graph_handler: USER_GRAPH_HANDLER
			user_handler: USER_HANDLER
			search_handler : SEARCH_HANDLER
			l_methods: WSF_REQUEST_METHODS
		do
			create l_options_filter.make (router)
			create root_handler
			create render_handler
			create register_handler
			create user_graph_handler
			create login_handler
			create user_handler
			create graph_handler
			create search_handler

				-- user login authentication filter
			create user_login_authentication_filter
			user_login_authentication_filter.set_next (login_handler)

				-- user authentication filter
			create user_authentication_filter
			user_authentication_filter.set_next (user_handler)

				-- user graph authentication filter
			create user_graph_authentication_filter
			user_graph_authentication_filter.set_next (user_graph_handler)

				-- the uri templates that we have here are opaque, only for API developer.
				-- the client should don't take care of it

				-- root
			create l_methods
			l_methods.enable_options
			l_methods.enable_get
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make ("/", root_handler), l_methods)

				-- register a user
			create l_methods
			l_methods.enable_options
			l_methods.enable_get
			l_methods.enable_post
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make_trailing_slash_ignored (register_uri, register_handler), l_methods)

				-- login a user
			router.map_with_request_methods (create {WSF_URI_CONTEXT_MAPPING [FILTER_HANDLER_CONTEXT]}.make_trailing_slash_ignored (login_uri, user_login_authentication_filter), router.methods_GET)

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
			router.map_with_request_methods (create {WSF_URI_TEMPLATE_MAPPING}.make_from_template (graph_uri_page_template, graph_handler), router.methods_GET)

				--user
			router.handle_with_request_methods (user_id_uri_template.template, user_authentication_filter, router.methods_GET)

				-- user_graph handler
			router.handle_with_request_methods (user_graph_uri.template, user_graph_authentication_filter, router.methods_GET_POST)
			router.handle_with_request_methods (user_graph_id_uri_template.template, user_graph_authentication_filter, router.methods_GET_PUT_DELETE)

				-- queries
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make_trailing_slash_ignored (queries_uri, search_handler), router.methods_GET)


			router.handle_with_request_methods ("/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make_hidden (router), router.methods_GET)
		end

	setup_filter
			-- Setup `filter'
		do
			filter.set_next (Current)
		end

feature -- Execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
		do
			initialize_converters (json)
			Precursor (req, res)
		end

	execute_default (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- I'm using this method to handle the method not allowed response
			-- in the case that the given uri does not have a corresponding http method
			-- to handle it, or the resource is not found in the server
		local
			h: HTTP_HEADER
			l_description: STRING
			l_cj : CJ_COLLECTION
			l_allow : STRING
			def: WSF_DEFAULT_ROUTER_RESPONSE
		do
			initialize_converters (json)
			if req.content_length_value > 0 then
				req.input.read_string (req.content_length_value.as_integer_32)
			end
			if req.is_content_type_accepted ("text/html") then
				create def.make_with_router (req, router)
				def.set_documentation_included (True)
				res.send (def)
			else
				create h.make
				h.put_content_type ("application/vnd.collection+json")
				l_cj := collection_json_root_builder (req)

				create l_allow.make_empty
				across router.allowed_methods_for_request (req) as c loop
						l_allow.append (c.item)
						l_allow.append (",")
				end
				if not l_allow.is_empty then
					l_allow.remove_tail (1)
					l_description := req.request_method + req.request_uri + " is not allowed" + "%N"
					l_cj.set_error ( new_error ("Method not allowed", "002", l_description))

					h.put_header_key_value ({HTTP_HEADER_NAMES}.header_allow, l_allow)
					res.set_status_code ({HTTP_STATUS_CODE}.method_not_allowed)
				else
					l_description := req.request_method + req.request_uri + " is not found" + "%N"
					l_cj.set_error ( new_error ("Method not found", "005", l_description))
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
				end
				h.put_current_date
				res.put_header_text (h.string)
				if attached json.value (l_cj) as l_cj_answer then
					h.put_content_length (l_cj_answer.representation.count)
					res.put_string (l_cj_answer.representation)
				end
			end
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
