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

	db: SQLITE_DATABASE
			-- a shared db instance of sqlite, create the db if it does not exist.
		local
			l_modify: SQLITE_MODIFY_STATEMENT
			l_query: SQLITE_QUERY_STATEMENT
			has_graph_table: BOOLEAN
		once
			print ("%NOpening Database...%N")

				-- Open/create a Database.
			create Result.make_create_read_write ("graph.sqlite")
			create l_query.make ("SELECT name FROM sqlite_master ORDER BY name;", Result)
			across
				l_query.execute_new as c
			loop
				if c.item.count >= 1 and then attached c.item.string_value (1) as l_table_name then
					print (" - table: " + l_table_name + "%N")
					has_graph_table := l_table_name.is_case_insensitive_equal ("graph")
				end
			end

				-- Create a new table
			if not has_graph_table then
				create l_modify.make ("CREATE TABLE IF NOT EXISTS GRAPH(id INTEGER PRIMARY KEY, description TEXT, title VARCHAR(30),content TEXT);", Result)
				l_modify.execute
				if l_modify.changes_count > 0 then
					print ("Graph Table created.%N")
				end
			end
		end

end
