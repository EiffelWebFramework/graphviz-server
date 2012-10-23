note
	description: "Summary description for {LOGGER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	FILE_LOGGER

inherit
	LOGGER

create
	make

feature {NONE} -- Initialization

	make (f: like file)
		do
			file := f
		end

	file: FILE

feature -- Operation

	log (m: READABLE_STRING_8)
		do
			if file.is_open_write then
				file.put_string (m)
				file.put_new_line
			end
		end

end
