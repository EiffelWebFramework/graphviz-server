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

create
	make

feature {NONE} -- Initialization

	make
		do
			initialize_router
			set_service_option ("port", 9090)
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
			router.handle_with_request_methods ("/", root_handler, router.methods_GET)
			router.handle_with_request_methods ("/graph", graph_handler, router.methods_POST + router.methods_GET)
			router.handle_with_request_methods ("/graph/{id}", graph_handler, router.methods_GET + router.methods_DELETE + router.methods_PUT)
			router.handle_with_request_methods ("/graph/{id}/render;{type}", render_handler, router.methods_GET)
		end

		--	setup_router_2
		--		local
		--			create_graph_handler: CREATE_GRAPH_HANDLER
		--			update_graph_handler: UPDATE_GRAPH_HANDLER
		--			rerieve_graph_handler : RETRIEVE_GRAPH_HANDLER
		--			trash_graph_handler : TRASH_GRAPH_HANDLER
		--		do
		--			create create_graph_handler
		--			create update_graph_handler
		--			create rerieve_graph_handler
		--			create trash_graph_handler
		--			-- the uri templates that we have here are opaque, only for API developer.
		--			-- the client should don't take care of it

		--			--create a graph
		--			router.handle_with_request_methods ("/graph", create_graph_handler, router.methods_POST)
		--			router.handle_with_request_methods ("/graph/{id}", create_graph_handler, router.methods_PUT)

		--			--update a graph
		--			router.handle_with_request_methods ("/graph/{id}", update_graph_handler, router.methods_PUT)

		--			-- retrieve a graph
		--			router.handle_with_request_methods ("/graph/{id}", update_graph_handler, router.methods_GET)

		--			-- delete a graph
		--			router.handle_with_request_methods ("/graph/{id}", update_graph_handler, router.methods_GET)

		--		end

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
