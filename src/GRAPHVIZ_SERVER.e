note
	description: "REST Buck server"
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPHVIZ_SERVER

inherit
	ANY

	WSF_URI_TEMPLATE_ROUTED_SERVICE

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
			initialize_router
			initialize_graphviz
			create {WSF_SERVICE_LAUNCHER_OPTIONS_FROM_INI} service_options.make_from_file ("server.ini")
--			set_service_option ("port", 9090)
			make_and_launch
		end

	setup_router
			--option1
		local
			render_handler: RENDER_HANDLER
			graph_handler: GRAPH_HANDLER
			root_handler: ROOT_HANDLER
		do
			create graph_handler
			create root_handler
			create render_handler
				-- the uri templates that we have here are opaque, only for API developer.
				-- the client should don't take care of it
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make ("/", root_handler), router.methods_GET)
			router.map_with_request_methods (create {WSF_URI_MAPPING}.make_trailing_slash_ignored (graph_uri, graph_handler), router.methods_GET_POST)
			router.map_with_request_methods (create {WSF_URI_TEMPLATE_MAPPING}.make_from_template (graph_id_type_uri_template, render_handler), router.methods_GET)
			router.map_with_request_methods (create {WSF_URI_TEMPLATE_MAPPING}.make_from_template (graph_id_uri_template, graph_handler), router.methods_GET_PUT_DELETE)
		end

feature -- Execution

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
