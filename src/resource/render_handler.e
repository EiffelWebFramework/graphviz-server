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

	GRAPH_MANAGER
	GRAPHVIZ_FORMATS

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

feature --HTTP Methods

	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found
		do
			if attached req.orig_path_info as orig_path then
				if attached {WSF_STRING} req.path_parameter ("id") as l_id and then attached {WSF_STRING} req.path_parameter ("type") as l_type then
					if attached retrieve_by_id (l_id.value.to_integer_32) as l_graph then
						if is_supported (l_type.value) then
							build_graph (l_graph, l_type.value)
							compute_response_get (req, res, l_id.value, l_type.value)
						else
							handle_bad_request_response ("Format [ " +l_type.value + " ] is not supported ", req, res)
						end
					else
						handle_resource_not_found_response ("Graph not found", req, res)
					end
				else
					handle_resource_not_found_response ("Graph not found", req, res)
				end
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; id: STRING_32; type: STRING_32)
		local
			h: HTTP_HEADER
			l_msg: STRING
			f: RAW_FILE
		do
			l_msg := ""
			create f.make_open_read (document_root + "\Graph_" + id + "." + type)
			if f.exists and then f.is_access_writable then
				f.read_stream (f.count)
				f.close
				l_msg := f.last_string
			end
			create h.make
			set_content_type (h,type)
			h.put_content_length (l_msg.count)
			if attached req.request_time as time then
				h.add_header ("Date:" + time.formatted_out ("ddd,[0]dd mmm yyyy [0]hh:[0]mi:[0]ss.ff2") + " GMT")
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (l_msg)
		end

	collection_json_root (req: WSF_REQUEST): STRING
		do
			create Result.make_from_string (collection_json_root_tpl)
			if attached req.http_host as l_host then
				Result.replace_substring_all ("$ROOT_URL", "http://" + l_host)
			else
				Result.replace_substring_all ("$ROOT_URL", "")
			end
		end

	collection_json_root_tpl: STRING = "[
					{
			   	 "collection": {
			        "items": [],
			        "links": [
			            {
			                "href": "$ROOT_URL/graph",
			                "prompt": "Graph List",
			                "rel": "Graph"
			            },
			            {
			                "href": "$ROOT_URL/user",
			                "prompt": "User List",
			                "rel": "Users"
			            }
			        ],
			        "queries": [],
			        "templates": [],
			        "version": "1.0"
			    	}
				}
		]"

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

	build_graph (a_graph: GRAPH; type: STRING)
		do
			create_file (document_root + "\" + "temp" + a_graph.id.out + ".graphviz", a_graph.content)
			generate_graphs (document_root + "\" + "temp" + a_graph.id.out + ".graphviz", "Graph_" + a_graph.id.out, type)
		end

	last_error: INTEGER

	generate_graphs (content_file: STRING; name: STRING; type: STRING)
		local
			gcb: GRAPHVIZ_COMMAND_BUILDER
			str: detachable STRING
		do
				--create gcb.make_with_format ({GRAPHVIZ_FORMATS}.jpg,content_file,name)
			create gcb.make_with_format (type, content_file, name)
			print ("Graph generation%N")
			if attached gcb.command as command then
				str := output_of_command (command, document_root)
				if attached str as s then
					print (s + "%N")
				else
					print ("Nothing!!")
				end
			end
			print ("End Process!!!")
		end

	output_of_command (a_cmd, a_dir: STRING): detachable STRING
			-- Output of command `a_cmd' launched in directory `a_dir'.
		require
			cmd_attached: a_cmd /= Void
			dir_attached: a_dir /= Void
		local
			pf: PROCESS_FACTORY
			p: PROCESS
			retried: BOOLEAN
		do
			if not retried then
				last_error := 0
				create Result.make (10)
				create pf
				p := pf.process_launcher_with_command_line (a_cmd, a_dir)
				p.set_hidden (True)
				p.set_separate_console (False)
				p.redirect_input_to_stream
				p.redirect_output_to_agent (agent  (res: STRING; s: STRING)
					do
						if s /= Void then
							res.append_string (s)
						end
					end (Result, ?))
				p.launch
				p.wait_for_exit
			else
				last_error := 1
			end
		rescue
			retried := True
			retry
		end

feature {NONE} --Implementation

	set_content_type (header : HTTP_HEADER; type : STRING)
			-- set header contenty base on `type'
		do
			if  type ~ "pdf" then
			        header.put_content_type ("application/pdf")
			elseif type ~ "gif" then
			        header.put_content_type_image_gif
			elseif type ~ "jpg" then
			        header.put_content_type_image_jpg
			else
			        header.put_content_type_text_plain -- default case
			end
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
