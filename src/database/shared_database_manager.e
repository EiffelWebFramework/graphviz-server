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
			has_graphs_table: BOOLEAN
			has_users_table: BOOLEAN
		once ("THREAD")
			io.error.put_string ("%NOpening Database...%N")

				-- Open/create a Database.
			create Result.make_create_read_write ("graph.sqlite")
			create l_query.make ("SELECT name FROM sqlite_master ORDER BY name;", Result)
			across
				l_query.execute_new as c
			loop
				if c.item.count >= 1 and then attached c.item.string_value (1) as l_table_name then
					io.error.put_string (" - table: " + l_table_name + "%N")
					if l_table_name.is_case_insensitive_equal ("graphs") then
						has_graphs_table := True
					elseif l_table_name.is_case_insensitive_equal ("users") then
						has_users_table := True
					end
				end
			end

				-- Create a new table users
			if not has_users_table then
				create l_modify.make ("CREATE TABLE IF NOT EXISTS USERS(user_id INTEGER NOT NULL PRIMARY KEY, user_name TEXT UNIQUE, password TEXT);", Result)
				l_modify.execute
				if l_modify.changes_count > 0 then
					io.error.put_string ("USERS Table created.%N")
				end
			end

				-- Create a new table graphs
			if not has_graphs_table then
				create l_modify.make ("CREATE TABLE IF NOT EXISTS GRAPHS(graph_id INTEGER NOT NULL PRIMARY KEY, description TEXT, title VARCHAR(30), content TEXT, user_id INTEGER NOT NULL REFERENCES USERS);", Result)
				l_modify.execute
				if l_modify.changes_count > 0 then
					io.error.put_string ("Graphs Table created.%N")
				end
			end
		end

feature -- {EQA_TEST_SET}

	db_test (db_name: STRING): SQLITE_DATABASE
			-- a shared db instance of sqlite, create the db from scratch use only in test cases
		local
			l_modify: SQLITE_MODIFY_STATEMENT
			l_query: SQLITE_QUERY_STATEMENT
		once ("OBJECT")
			io.error.put_string ("%NOpening Database...%N")

				-- Open/create a Database.
			create Result.make_create_read_write (db_name)
			create l_query.make ("SELECT name FROM sqlite_master ORDER BY name;", Result)
			across
				l_query.execute_new as l_cursor
			loop
				io.error.put_string (" - table: " + l_cursor.item.string_value (1) + "%N")
			end

				-- Drop tables
				-- Remove any existing table

			create l_modify.make ("DROP TABLE IF EXISTS GRAPHS;", Result)
			l_modify.execute
			create l_modify.make ("DROP TABLE IF EXISTS USERS;", Result)
			l_modify.execute

				-- Create a new table users
			create l_modify.make ("CREATE TABLE USERS(user_id INTEGER NOT NULL PRIMARY KEY, user_name TEXT UNIQUE, password TEXT);", Result)
			l_modify.execute
			if l_modify.changes_count > 0 then
				io.error.put_string ("USERS Table created.%N")
			end

				-- Create a new table graphs
			create l_modify.make ("CREATE TABLE GRAPHS (graph_id INTEGER NOT NULL PRIMARY KEY, description TEXT, title VARCHAR(30), content TEXT, user_id INTEGER NOT NULL REFERENCES USERS);", Result)
			l_modify.execute
			if l_modify.changes_count > 0 then
				io.error.put_string ("Graphs Table created.%N")
			end
		end

end
