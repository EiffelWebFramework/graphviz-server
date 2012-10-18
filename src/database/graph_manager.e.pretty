note
	description: "Summary description for {GRAPH_MANAGER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPH_MANAGER

inherit

	SHARED_DATABASE_MANAGER

feature -- Access

	last_row_id: INTEGER_64

feature -- Query

	retrieve_by_id (an_id: INTEGER): detachable GRAPH
			-- retrive all graphs from db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			last_retrieve_by_id_result := Void

				-- Query the contents of the Example table

			create l_query.make ("SELECT id,description,title,content FROM GRAPH where id = :ID;", db)
			check
				l_query_is_compiled: l_query.is_compiled
			end
			l_query.execute_with_arguments (agent  (ia_row: SQLITE_RESULT_ROW): BOOLEAN
				local
					l_graph: GRAPH
					l_descr: detachable STRING_32
					l_title: detachable STRING_32
				do
					if not ia_row.is_null (2) then
						l_descr := ia_row.string_value (2).to_string_32
					end
					if not ia_row.is_null (3) then
						l_title := ia_row.string_value (3).to_string_32
					end
					create l_graph.make (ia_row.string_value (4).to_string_32, l_title, l_descr)
					l_graph.set_id (ia_row.integer_value (1))
					last_retrieve_by_id_result := l_graph
				end, [create {SQLITE_INTEGER_ARG}.make (":ID", an_id)])
			Result := last_retrieve_by_id_result
		end

	retrieve_all: detachable LIST [GRAPH]
			-- retrive all graphs from db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			create {ARRAYED_LIST [GRAPH]} last_retrieve_all_result.make (0)

				-- Query the contents of the Example table
			create l_query.make ("SELECT id,description,title,content FROM GRAPH;", db)
			check
				l_query_is_compiled: l_query.is_compiled
			end
			l_query.execute (agent  (ia_row: SQLITE_RESULT_ROW): BOOLEAN
				local
					l_graph: GRAPH
					l_descr: detachable STRING_32
					l_title: detachable STRING_32
				do
					if not ia_row.is_null (2) then
						l_descr := ia_row.string_value (2).to_string_32
					end
					if not ia_row.is_null (3) then
						l_title := ia_row.string_value (3).to_string_32
					end
					create l_graph.make (ia_row.string_value (4).to_string_32, l_title, l_descr)
					l_graph.set_id (ia_row.integer_value (1))
					if attached last_retrieve_all_result as lrq then
						lrq.force (l_graph)
					end
				end)
			Result := last_retrieve_all_result
		end

feature -- Update

	update (a_graph: GRAPH)
			-- update a graph with `a_graph'
		local
			l_update: SQLITE_MODIFY_STATEMENT
			l_descr_arg: SQLITE_BIND_ARG [ANY]
			l_title_arg: SQLITE_BIND_ARG [ANY]
		do
				-- Create an update statement with variables

			create l_update.make ("UPDATE GRAPH SET description=:DESCRIPTION, title= :TITLE, content= :CONTENT WHERE id= :ID;", db)
			check
				l_update_is_compiled: l_update.is_compiled
			end
				-- Commit handling
			db.begin_transaction (False)
			if attached a_graph.description as descr then
				create {SQLITE_STRING_ARG} l_descr_arg.make (":DESCRIPTION", descr)
			else
				create {SQLITE_NULL_ARG} l_descr_arg.make (":DESCRIPTION")
			end
			if attached a_graph.title as title then
				create {SQLITE_STRING_ARG} l_title_arg.make (":TITLE", title)
			else
				create {SQLITE_NULL_ARG} l_title_arg.make (":TITLE")
			end
			l_update.execute_with_arguments ([l_descr_arg, l_title_arg, create {SQLITE_STRING_ARG}.make (":CONTENT", a_graph.content), create {SQLITE_INTEGER_ARG}.make (":ID", a_graph.id)])

				-- Commit changes
			db.commit
		end

feature -- Insert

	insert (a_graph: GRAPH)
			-- insert a new graph `a_graph'
		local
			l_insert: SQLITE_INSERT_STATEMENT
			l_descr_arg: SQLITE_BIND_ARG [ANY]
			l_title_arg: SQLITE_BIND_ARG [ANY]
		do
				-- Create a insert statement with variables
			create l_insert.make ("INSERT INTO GRAPH (description,title,content) VALUES (:DESCRIPTION, :TITLE, :CONTENT);", db)
			check
				l_insert_is_compiled: l_insert.is_compiled
			end

				-- Commit handling
			db.begin_transaction (False)
			if attached a_graph.description as descr then
				create {SQLITE_STRING_ARG} l_descr_arg.make (":DESCRIPTION", descr)
			else
				create {SQLITE_NULL_ARG} l_descr_arg.make (":DESCRIPTION")
			end
			if attached a_graph.title as title then
				create {SQLITE_STRING_ARG} l_title_arg.make (":TITLE", title)
			else
				create {SQLITE_NULL_ARG} l_title_arg.make (":TITLE")
			end
			l_insert.execute_with_arguments ([l_descr_arg, l_title_arg, create {SQLITE_STRING_ARG}.make (":CONTENT", a_graph.content)])

				-- Commit changes
			db.commit
			last_row_id := l_insert.last_row_id
		end

feature -- Delete

	delete_by_id (an_id: INTEGER)
			-- delte a row with ID `an_id' from db
		local
			l_delete: SQLITE_MODIFY_STATEMENT
		do
				-- Create a DELETE statement with variables
			create l_delete.make ("DELETE FROM GRAPH WHERE id = :ID;", db)
			check
				l_delete_is_compiled: l_delete.is_compiled
			end

				-- Commit handling
			db.begin_transaction (False)
			l_delete.execute_with_arguments ([create {SQLITE_INTEGER_ARG}.make (":ID", an_id)])

				-- Commit changes
			db.commit
		end

feature {NONE} -- Implementation

	last_retrieve_all_result: detachable LIST [GRAPH]

	last_retrieve_by_id_result: detachable GRAPH

end
