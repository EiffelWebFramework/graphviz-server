note
	description: "Summary description for {GRAPHVIZ_UTILITIES}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPHVIZ_UTILITIES

inherit

	PROCESS_HELPER

feature -- Logger

	logger: detachable LOGGER

	set_logger (a_logger: like logger)
		do
			logger := a_logger
		end

	log (m: READABLE_STRING_8)
		do
			if attached logger as l_logger then
				l_logger.log (m)
			end
		end

feature -- Supported formats

	supported_formats: detachable LIST [READABLE_STRING_8]
		local
			cmd: STRING_8
			p: INTEGER
		do
			create cmd.make_from_string (dot_command)
			cmd.append_string_general (" -T?")
			if attached output_of_command (cmd, Void) as s then
				p := s.substring_index ("Use one of:", 1)
				if p > 0 then
					if attached s.substring (p + 12, s.count) as l_types then
						l_types.left_adjust
						l_types.right_adjust
						Result := l_types.split (' ')
					end
				end
			end
			if Result = Void then
				log ("Unable to retrieve supported format.")
			end
		end

feature -- Render

	render_graph_into_file (a_graph_file_name: READABLE_STRING_GENERAL; a_type: READABLE_STRING_GENERAL; a_file_name: READABLE_STRING_GENERAL)
		require
			ascii_graph_file_name: a_graph_file_name.is_valid_as_string_8
			ascii_file_name: a_file_name.is_valid_as_string_8
		do
				-- FIXME: handle unicode properly  (see EiffelStudio 7.2)
			log ("Graph generation%N")
				--create gcb.make_with_format ({GRAPHVIZ_FORMATS}.jpg,content_file,name)
			if attached dot_rendering_command (a_graph_file_name.to_string_8, a_type.to_string_8, a_file_name.to_string_8) as command then
				if attached output_of_command (command, Void) as s then
					log (s)
				else
					log ("Nothing!!")
				end
			end
			log ("End Process!!!")
		end

feature {NONE} -- Initialization

	dot_rendering_command (a_graph_file_name: READABLE_STRING_8; a_type: READABLE_STRING_8; a_file_name: READABLE_STRING_8): STRING_8
			-- example : dot -Tpng graph.graphviz -o -v graph2.png
		do
			create Result.make_from_string (dot_command)
			Result.append (" ")
			Result.append ("-T")
			Result.append (a_type)
			Result.append (" ")
			Result.append (a_graph_file_name)
			Result.append (" ")
			Result.append ("-o -v ")
			Result.append (a_file_name + "." + a_type)
		end

	dot_command: STRING
		local
			e: EXECUTION_ENVIRONMENT
			fn: FILE_NAME
		once
			create e
			if attached e.get ("GRAPHVIZ_DOT_DIR") as d then
				create fn.make_from_string (d)
				fn.set_file_name ("dot")
				Result := fn.string
			else
				Result := "dot"
			end
		end

end
