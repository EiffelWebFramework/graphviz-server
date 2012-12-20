note
	description: "Summary description for {PROCESS_HELPER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	PROCESS_HELPER

feature -- Access	

	--output_of_command (a_cmd: READABLE_STRING_8; a_dir: detachable READABLE_STRING_GENERAL): detachable STRING
	output_of_command (a_cmd: READABLE_STRING_8; a_dir: detachable STRING; is_silent: BOOLEAN; a_error_buffer: detachable STRING): detachable STRING
			-- Output of command `a_cmd' launched in directory `a_dir'.
		require
			cmd_attached: a_cmd /= Void
		local
			pf: PROCESS_FACTORY
			p: PROCESS
			retried: BOOLEAN
			err: BOOLEAN
		do
			if not retried then
				err := False
				create Result.make (10)
				create pf
				p := pf.process_launcher_with_command_line (a_cmd, a_dir)
				p.set_hidden (True)
				p.set_separate_console (False)
				p.redirect_input_to_stream
				p.redirect_output_to_agent (agent  (res: STRING; s: STRING)
					do
						res.append_string (s)
					end (Result, ?)
				)
				p.redirect_error_to_same_as_output
				p.launch
				if not p.launched then
					if a_error_buffer /= Void then
						a_error_buffer.append ("Error: can not execute %"" + a_cmd + "%"%N")
					end
					io.error.put_string ("Error: can not execute %"" + a_cmd + "%"%N")
				else
					p.wait_for_exit
					if p.exit_code /= 0 then
						if not is_silent then
							io.error.put_string ("Error: exit code for %"" + a_cmd + "%" = "+ p.exit_code.out +"%N")
							io.error.put_string ("Output: " + Result + "%N")
							if a_error_buffer /= Void then
								a_error_buffer.append ("Output: " + Result + "%N")
							end
						end
					end
				end
			else
				err := True
				io.error.put_string ("Error: can not get output from %"" + a_cmd + "%"%N")
				if a_error_buffer /= Void then
					a_error_buffer.append ("Error: can not get output from %"" + a_cmd + "%"%N")
				end
			end
		rescue
			retried := True
			retry
		end

end
