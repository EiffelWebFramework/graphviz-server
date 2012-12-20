note
	description: "Summary description for {RENDER_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	RENDER_HANDLER

inherit

	WSF_URI_HANDLER
		rename
			execute as uri_execute,
			new_mapping as new_uri_mapping
		end

	WSF_URI_TEMPLATE_HANDLER
		rename
			execute as uri_template_execute,
			new_mapping as new_uri_template_mapping
		select
			new_uri_template_mapping
		end

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get
		end

	SHARED_DATABASE_API

	GRAPHVIZ_FORMATS

	COLLECTION_JSON_HELPER

	PROCESS_HELPER

	WSF_SELF_DOCUMENTED_HANDLER

feature -- Documentation

	mapping_documentation (m: WSF_ROUTER_MAPPING; a_request_methods: detachable WSF_REQUEST_METHODS): WSF_ROUTER_MAPPING_DOCUMENTATION
		do
			create Result.make (m)
			if attached {WSF_URI_TEMPLATE_MAPPING} m as l_uri_tpl then
				Result.add_description ("Render graph according to parameters%N")
				Result.add_description ("id: Graph's unique identifier%N")
				Result.add_description ("type: Rendering type")
			end
		end

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

feature -- Logging

	log (m: READABLE_STRING_GENERAL)
		do
			io.error.put_string (m.to_string_8)
		end

feature --HTTP Methods

	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found
		local
			l_cj: CJ_COLLECTION
		do
				--|TODO refactor code, too complex
			if attached {WSF_STRING} req.path_parameter ("uid") as l_id and then l_id.is_integer and then attached {WSF_STRING} req.path_parameter ("gid") as g_id and then g_id.is_integer and then attached {WSF_STRING} req.path_parameter ("type") as l_type then
				process_graph_render_with_user (req, res, l_type, g_id.integer_value, l_id.integer_value)
			elseif attached {WSF_STRING} req.path_parameter ("id") as l_id and then l_id.is_integer and then attached {WSF_STRING} req.path_parameter ("type") as l_type then
				process_graph_render (req, res, l_type, l_id.integer_value)
			else
				l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Resource Not found", "001", "Graph not found"))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
				end
			end
		end

	process_graph_render_with_user (req: WSF_REQUEST; res: WSF_RESPONSE; type: WSF_STRING; gid: INTEGER; uid: INTEGER)
		local
			m: STRING
			l_cj: CJ_COLLECTION
		do
			if attached graph_dao.retrieve_by_id_and_user_id (gid, uid) as l_graph then
				if is_supported (type.value) then
					build_graph (l_graph, uid, type.value)
					compute_response_get (req, res, uid.out, gid.out, type.value)
				else
					m := "Format [" + type.value + "] is not supported. Try one of the following: "
					across
						supported_formats as c
					loop
						m.append (c.item)
						m.append_character (' ')
					end
					l_cj := collection_json_root_builder (req)
					l_cj.set_error (new_error ("Bad request", "005", "Bad request"))
					if attached json.value (l_cj) as l_cj_answer then
						compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.bad_request)
					end
				end
			else
				l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Resource Not found", "001", "Graph not found"))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
				end
			end
		end

	process_graph_render (req: WSF_REQUEST; res: WSF_RESPONSE; type: WSF_STRING; gid: INTEGER)
		local
			l_cj : CJ_COLLECTION
			m : STRING
		do
			if attached graph_dao.retrieve_by_id (gid) as l_graph then
				if is_supported (type.value) then
					build_graph (l_graph, 0, type.value)
					compute_response_get (req, res, "0", gid.out, type.value)
				else
					m := "Format [" + type.value + "] is not supported. Try one of the following: "
					across
						supported_formats as c
					loop
						m.append (c.item)
						m.append_character (' ')
					end
					l_cj := collection_json_root_builder (req)
					l_cj.set_error (new_error ("Bad request", "005", "Bad request"))
					if attached json.value (l_cj) as l_cj_answer then
						compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.bad_request)
					end
				end
			else
				l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Resource Not found", "001", "Graph not found"))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.not_found)
				end
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; uid: STRING_32; gid: STRING_32; type: STRING_32)
		local
			h: HTTP_HEADER
			l_msg: STRING
			f: RAW_FILE
			fn: FILE_NAME
			l_cj: CJ_COLLECTION
		do
			l_msg := ""
			create fn.make_from_string (document_root)
			fn.set_file_name ("Graph_" + uid + "_" + gid + "." + type)
			create f.make (fn.string)
			if f.exists and then f.is_access_readable then
				f.open_read
				f.read_stream (f.count)
				f.close
				l_msg := f.last_string
				create h.make
				set_content_type (h, type)
				h.put_content_length (l_msg.count)
				if attached req.request_time as time then
					h.put_utc_date (time)
				end
				res.set_status_code ({HTTP_STATUS_CODE}.ok)
				res.put_header_text (h.string)
				res.put_string (l_msg)
			else
				l_cj := collection_json_root_builder (req)
				l_cj.set_error (new_error ("Internal Server Error", "006", "Unable to generate output %"" + type + "%" for graph %"" + gid.out + "%"."))
				if attached json.value (l_cj) as l_cj_answer then
					compute_response (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.internal_server_error)
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

feature -- Htdocs

	document_root: READABLE_STRING_8
			-- Document root to look for files or directories
		local
			e: EXECUTION_ENVIRONMENT
			dn: DIRECTORY_NAME
		once
			create e
			create dn.make_from_string (e.current_working_directory)
			dn.extend ("htdocs")
			Result := dn.string
			if Result [Result.count] = Operating_environment.directory_separator then
				Result := Result.substring (1, Result.count - 1)
			end
		ensure
			not Result.ends_with (Operating_environment.directory_separator.out)
		end

feature -- File Helper

	create_file (file: STRING; content: STRING_32)
		local
			f: PLAIN_TEXT_FILE
			--			l_content: STRING
		do
				-- FIXME: content will be converted to STRING_8 .. thus possible data loss
			create f.make_create_read_write (file)
			if f.exists and then f.is_access_writable then
				content.right_adjust
				f.put_string (content)
				f.close
			end
		end

feature -- Graphviz utils

	build_graph (a_graph: GRAPH; user_id: INTEGER; a_type: STRING)
		local
			fn, ofn: FILE_NAME
			u: GRAPHVIZ_UTILITIES
		do
			create fn.make_from_string (document_root)
			fn.set_file_name ("temp_" + user_id.out + "_" + a_graph.id.out)
			fn.add_extension ("graphviz")
			create_file (fn.string, a_graph.content)
			create ofn.make_from_string (document_root)
			ofn.set_file_name ("Graph_" + user_id.out + "_" + a_graph.id.out)
			create u
			u.set_logger (create {FILE_LOGGER}.make (io.error))
			u.render_graph_into_file (fn.string, a_type, ofn.string)
		end

feature {NONE} --Implementation

	set_content_type (header: HTTP_HEADER; type: STRING)
			-- set header contenty base on `type'
		do
			if attached mime_mapping.mime_type (type) as l_content_type then
				header.put_content_type (l_content_type)
			else
				if type.same_string ("png") then
					header.put_content_type_image_png
				elseif type.same_string ("svg") then
					header.put_content_type_image_svg_xml
				elseif type.same_string ("pdf") then
					header.put_content_type_application_pdf
				elseif type.same_string ("gif") then
					header.put_content_type_image_gif
				elseif type.same_string ("jpg") then
					header.put_content_type_image_jpg
				else
					header.put_content_type_text_plain -- default case
				end
			end
		end

	mime_mapping: HTTP_FILE_EXTENSION_MIME_MAPPING
		once
			create Result.make_default
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
