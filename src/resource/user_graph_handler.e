note
	description: "USER_GRAPH_HANDLER handle the graph resources for a particular user, it allow create, get one or all, delete and updates graphs per user"
	date: "$Date$"
	revision: "$Revision$"

class
	USER_GRAPH_HANDLER

inherit

	WSF_FILTER

	WSF_URI_TEMPLATE_HANDLER

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get,
			do_put,
			do_post,
			do_delete
		end

	COLLECTION_JSON_HELPER

	SHARED_DATABASE_API

	REFACTORING_HELPER

feature -- execute

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (req, res)
			execute_next (req, res)
		end

feature -- HTTP Methods

		--| The current implementation will use a simple authentication and authorization schema as a proof of concept
		--| we will inspect the header looking for : User:example and Password: test

		--| Right now conditional GET and PUT are not implemented.

	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found
		local
			l_cj: CJ_COLLECTION
		do
				--| TODO refactor code.
				--| GET need to handle two different kind of request now.
				--| The first case, /user/{id}/graph, mean retrieve all graphs, for the
				--| user with id {id}
				--| The second case, /user/{uid}/graph/{gid} with the path parameters uid and gid,
				--| in this case retrive the graph with the given id, for the given user id uid.
				--| Maybe the first case need to be refactored and removed to a new
				--| handler possibly the SEARCH_HANLDER.
			initialize_converters (json)
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {WSF_STRING} req.path_parameter ("gid") as g_id and then g_id.is_integer and then attached {USER} req.execution_variable ("user") as auth_user and then attached user_dao.retrieve_by_id (l_id.integer_value) as l_user then
						-- retrieve a graph identidied by uid and gid
					if l_user.id = auth_user.id then
						process_graph_by_user (req, res, g_id.integer_value, l_id.integer_value)
					elseif attached {USER} req.execution_variable ("user") as l_auth_user then
							-- Trying to access another user that the authenticated one,
							-- which is forbidden in this example...
						l_cj := collection_json_root_builder (req)
						l_cj.set_error (new_error ("Fobidden", "003", "You try to access the user " + l_id.value + " while authenticating with the user " + l_auth_user.id.out))
						if attached json.value (l_cj) as l_cj_answer then
							compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.forbidden)
						end
					end
				elseif attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {USER} req.execution_variable ("user") as auth_user and then attached {USER} user_dao.retrieve_by_id (l_id.integer_value) as l_user then
						-- retrieve all graphs

					if l_user.id = auth_user.id then
						process_graphs_by_user (req, res, l_id.integer_value)
					elseif attached {USER} req.execution_variable ("user") as l_auth_user then
							-- Trying to access another user that the authenticated one,
							-- which is forbidden in this example...
						l_cj := collection_json_root_builder (req)
						l_cj.set_error (new_error ("Fobidden", "003", "You try to access the user " + l_id.value + " while authenticating with the user " + l_auth_user.id.out))
						if attached json.value (l_cj) as l_cj_answer then
							compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.forbidden)
						end
					end
				end
			end
		end

	process_graph_by_user (req: WSF_REQUEST; res: WSF_RESPONSE; gid: INTEGER; uid: INTEGER)
		local
			l_cj: CJ_COLLECTION
		do
			if attached graph_dao.retrieve_by_id_and_user_id (gid, uid) as l_graph then
				l_cj := collection_json_user_graph_builder (req, uid, l_graph)
				build_item_user (req, uid, l_graph, l_cj)
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.ok)
				end
			else
				l_cj := collection_json_user_graph_builder (req, uid, Void)
				l_cj.set_error (new_error ("Resource not found", "001", "The graph id " + gid.out + " does not exist in the system for the user " + uid.out))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
				end
			end
		end

	process_graphs_by_user (req: WSF_REQUEST; res: WSF_RESPONSE; uid: INTEGER)
		local
			l_cj: CJ_COLLECTION
		do
			if attached graph_dao.retrieve_all_by_user_id (uid) as graphs then
				l_cj := collection_json_user_graph_builder (req, uid, Void)
				across
					graphs as ic
				loop
					build_item_user (req, uid, ic.item, l_cj)
				end
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.ok)
				end
			end
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
			-- If the request post is SUCCESS, the server will create the graph and will response with
			-- HTTP_RESPONSE 201 CREATED, the Location header will contains the newly created graph's URI
			-- if the request post is not SUCCESS, the server will response with
			-- HTTP_RESPONSE 400 BAD REQUEST, the client send a bad request
			-- HTTP_RESPONSE 500 INTERNAL_SERVER_ERROR, when the server can deliver the request
		local
			l_post: STRING
			l_helper: WSF_RESOURCE_HANDLER_HELPER
			l_cj: CJ_COLLECTION
		do
			create l_helper
			create l_post.make_empty
			req.read_input_data_into (l_post)

			if attached extract_cj_request (l_post) as l_graph and then attached {USER} req.execution_variable ("user") as auth_user and then attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {USER} user_dao.retrieve_by_id (l_id.integer_value) as l_user then
					-- save graph
					-- return the location uri of the graph and return a 201
					--| Here maybe we need to verify if the save action in
					--| was succesful or not, if not was successfull, we need to
					--| send a 50x error.
				if l_user.id = auth_user.id then
					graph_dao.insert (l_graph, l_id.integer_value)
					l_graph.set_id (graph_dao.last_row_id.to_integer_32)
					compute_response_post (req, res, l_id.integer_value, l_graph)
				elseif attached {USER} req.execution_variable ("user") as l_auth_user then
						-- Trying to access another user that the authenticated one,
						-- which is forbidden in this example...
					l_cj := collection_json_root_builder (req)
					l_cj.set_error (new_error ("Fobidden", "003", "You try to access the user " + l_id.value + " while authenticating with the user " + l_auth_user.id.out))
					if attached json.value (l_cj) as l_cj_answer then
						compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.forbidden)
					end
				end
			else
				l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Bad request", "005", l_post + "%N is not a valid Graph"))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.bad_request)
				end
			end
		end

	compute_response_post (req: WSF_REQUEST; res: WSF_RESPONSE; user_id: INTEGER; a_graph: GRAPH)
		local
			h: HTTP_HEADER
			l_location: STRING
		do
				--| Here we send a response with status code 201 and the uri of
				--| the new resource.
				--| Other option is send a 201 and a redirect to http://127.0.0.1:9090/graph
				--| the problem here is that redirect action rewrite the location, I'm not
				--| sure if that behavior is ok.
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			h.add_header_key_value ("Access-Control-Allow-Origin","*")

			l_location := req.absolute_script_url (user_graph_id_uri (user_id, a_graph.id))
			h.put_location (l_location)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.created)
			res.put_header_text (h.string)
		end

	do_delete (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Here we use DELETE to cancel a graph description.
			-- 200 if is ok
			-- 404 Resource not found
			-- 500 if we have an internal server error
		local
			l_cj : CJ_COLLECTION
		do
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {USER} req.execution_variable ("user") as auth_user and then attached {WSF_STRING} req.path_parameter ("gid") as g_id and then g_id.is_integer and then attached {USER} user_dao.retrieve_by_id (l_id.integer_value) as l_user then
					if l_user.id = auth_user.id then
						graph_dao.delete_by_id (g_id.integer_value, l_id.integer_value)
						compute_response_delete (req, res)
					elseif attached {USER} req.execution_variable ("user") as l_auth_user then
							-- Trying to access another user that the authenticated one,
							-- which is forbidden in this example...
							l_cj := collection_json_root_builder (req)
							l_cj.set_error (new_error ("Fobidden", "003", "You try to access the user " + l_id.value + " while authenticating with the user " + l_auth_user.id.out))
							if attached json.value (l_cj) as l_cj_answer then
								compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.forbidden)
							end
					end
				else
						l_cj := collection_json_root_builder (req)
						l_cj.set_error (new_error ("Resource not found", "001", "Resource " + req.request_uri + " not found "))
						if attached json.value (l_cj) as l_cj_answer then
							compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
						end

				end
			end
		end

	compute_response_delete (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			h.add_header_key_value ("Access-Control-Allow-Origin","*")

			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.no_content)
			res.put_header_text (h.string)
		end

	do_put (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Updating a resource with PUT
			-- A successful PUT request will not create a new resource, instead it will
			-- change the state of the resource identified by the current uri.
			-- If success we response with 200.
			-- 404 if the graph is not found
			-- 400 in case of a bad request
			-- 500 internal server error
		local
			l_put: STRING
			l_helper: WSF_RESOURCE_HANDLER_HELPER
			l_cj : CJ_COLLECTION
		do
				--|WSF_RESOURCE_CONTEXT_HANDLER_HELPER does not have a retrieve_data, it should.

			create l_helper
			l_put := l_helper.retrieve_data (req)
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {WSF_STRING} req.path_parameter ("gid") as g_id and then g_id.is_integer and then attached {USER} req.execution_variable ("user") as auth_user and then attached {USER} user_dao.retrieve_by_id (l_id.integer_value) as l_user then
					if l_user.id = auth_user.id then
						if attached extract_cj_request (l_put) as lreq_graph and then attached graph_dao.retrieve_by_id_and_user_id (g_id.integer_value, l_id.integer_value) as ldb_graph then
							ldb_graph.set_description (lreq_graph.description)
							ldb_graph.set_title (lreq_graph.title)
							ldb_graph.set_content (lreq_graph.content)
							graph_dao.update (ldb_graph, l_id.integer_value)
							compute_response_put (req, res)
						else
								l_cj := collection_json_root_builder (req)
								l_cj.set_error (new_error ("Resource not found", "001", orig_path + " not found"))
								if attached json.value (l_cj) as l_cj_answer then
									compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
								end
						end
					elseif attached {USER} req.execution_variable ("user") as l_auth_user then
							-- Trying to access another user that the authenticated one,
							-- which is forbidden in this example...
							l_cj := collection_json_root_builder (req)
							l_cj.set_error (new_error ("Fobidden", "003", "You try to access the user " + l_id.value + " while authenticating with the user " + l_auth_user.id.out))
							if attached json.value (l_cj) as l_cj_answer then
								compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.forbidden)
							end
					end
				end
			end
		end

	compute_response_put (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			h: HTTP_HEADER
		do
				--| Here we send a response with status code 200,
				--| Maybe we also can send a redirect to the resource.
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
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
