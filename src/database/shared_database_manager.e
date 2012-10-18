note
	description: "Summary description for {SHARED_DATABASE_MANAGER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SHARED_DATABASE_MANAGER
inherit
	SQLITE_SHARED_API

feature -- db Manager

	db : SQLITE_DATABASE
		-- a shared db instance of sqlite, create the db if it does not exist.
		local
			l_modify: SQLITE_MODIFY_STATEMENT
			l_query: SQLITE_QUERY_STATEMENT
		once
			print ("%NOpening Database...%N")

				-- Open/create a Database.
			create Result.make_create_read_write ("graph.sqlite")

			create l_query.make ("SELECT name FROM sqlite_master ORDER BY name;", Result)
			across l_query.execute_new as l_cursor loop
				print (" - table: " + l_cursor.item.string_value (1) + "%N")
			end


			print ("Creating Graph Table...%N")

				-- Create a new table
			create l_modify.make ("CREATE TABLE IF NOT EXISTS GRAPH(id INTEGER PRIMARY KEY, description TEXT, title VARCHAR(30),content TEXT);", Result)
			l_modify.execute

	 end
end
