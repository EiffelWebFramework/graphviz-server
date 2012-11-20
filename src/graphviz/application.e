note
	description : "graphviz application root class"
	date        : "$Date$"
	revision    : "$Revision$"

class
	APPLICATION


create
	make

feature {NONE} -- Initialization

	make
			-- Run application.
		local
		 gcb : GRAPHVIZ_COMMAND_BUILDER
		 str : detachable STRING
		do
			create gcb.make_with_format ({GRAPHVIZ_FORMATS}.jpg, "test.graphviz", "test")
			--| Add your code here
			print ("Graph generation%N")
			if attached gcb.command as command then
				str :=output_of_command(command,directory)
				if attached str as s then
					print(s+"%N")
				else
					print ("Nothing!!")
				end

			end
			print("End Process!!!")
		end

	last_error: INTEGER

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
				p.redirect_output_to_agent (agent (res: STRING; s: STRING)
					do
						if s /= Void then
							res.append_string (s)
						end
					end (Result, ?)
					)
				p.launch
				p.wait_for_exit
			else
				last_error := 1
			end
		rescue
			retried := True
			retry
		end


feature -- resources
	directory : STRING = "c:\tmp"

end
