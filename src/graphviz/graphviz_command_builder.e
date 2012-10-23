note
	description: "Summary description for {GRAPHVIZ_COMMAND_BUILDER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPHVIZ_COMMAND_BUILDER
	-- example : dot -Tgif graph.graphviz -o -v graph2.gif

create
	make_with_format

feature -- command

	command: STRING

feature -- Initialization

	make_with_format (format: READABLE_STRING_32; file: READABLE_STRING_32; name: READABLE_STRING_32)
			-- validate format
			-- validate name
			-- validate file
		do
			set_command (format, file, name)
		end

	set_command (format: READABLE_STRING_32; file: READABLE_STRING_32; name: READABLE_STRING_32)
		do
			create command.make_empty ();
			if attached command as cm then
				cm.append (dot)
				cm.append (" ")
				cm.append ("-T")
				cm.append (format.as_string_8)
				cm.append (" ")
				cm.append (file)
				cm.append (" ")
				cm.append ("-o -v ")
				cm.append (name + "." + format)
			end
		end

feature --{NONE}

	dot: STRING = "dot"

end
