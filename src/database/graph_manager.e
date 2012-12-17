note
	description: "Summary description for {GRAPH_MANAGER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPH_MANAGER

inherit

	ABSTRACT_MANAGER
		rename
			default_create as am_default_create
		end

	SHARED_DATABASE_MANAGER
		rename
			default_create as sdm_default_create
		select
			sdm_default_create
		end

feature -- Initialization

	default_create
		do
			set_up_db_mgr (db)
		end

feature -- Access

	last_row_id: INTEGER_64

feature -- Query

	retrieve_by_id (an_id: INTEGER): detachable GRAPH
			-- retrive graph by id from db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			last_retrieve_by_id_result := Void

				-- Query the contents of the Example table

			create l_query.make ("SELECT graph_id,description,title,content FROM GRAPHS where graph_id = :ID;", db)
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

	retrieve_page (index : INTEGER; offset : INTEGER): detachable LIST [GRAPH]
			-- retrive page graphs per index and offset.
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			create {ARRAYED_LIST [GRAPH]} last_retrieve_page_result.make (0)

				-- Query the contents of the Example table
			create l_query.make ("SELECT graph_id,description,title,content FROM GRAPHS LIMIT :INDEX , :OFFSET;", db_mgr)
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
					if attached last_retrieve_page_result as lrq then
						lrq.force (l_graph)
					end
				end,[create {SQLITE_INTEGER_ARG}.make (":INDEX", index), create {SQLITE_INTEGER_ARG}.make (":OFFSET", offset)])
			Result := last_retrieve_page_result
		end

	retrieve_count: INTEGER
			-- retrive the count of graphs in the db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			create {ARRAYED_LIST [GRAPH]} last_retrieve_all_result.make (0)

				-- Query the contents of the Example table
			create l_query.make ("SELECT COUNT(*) FROM GRAPHS;", db_mgr)
			check
				l_query_is_compiled: l_query.is_compiled
			end
			l_query.execute (agent  (ia_row: SQLITE_RESULT_ROW): BOOLEAN
				do
					last_integer_count := ia_row.integer_value (1)
				end)
			Result := last_integer_count
		end

	retrieve_all: detachable LIST [GRAPH]
			-- retrive all graphs from db_mgr
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			create {ARRAYED_LIST [GRAPH]} last_retrieve_all_result.make (0)

				-- Query the contents of the Example table
			create l_query.make ("SELECT graph_id,description,title,content FROM GRAPHS;", db_mgr)
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

	retrieve_by_id_and_user_id (an_id: INTEGER; user_id: INTEGER): detachable GRAPH
			-- retrive graph by id from db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			last_retrieve_by_id_result := Void

				-- Query the contents of the Example table

			create l_query.make ("SELECT graph_id,description,title,content FROM GRAPHS where graph_id = :ID and user_id = :USER_ID;", db_mgr)
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
				end, [create {SQLITE_INTEGER_ARG}.make (":ID", an_id), create {SQLITE_INTEGER_ARG}.make (":USER_ID", user_id)])
			Result := last_retrieve_by_id_result
		end

	retrieve_all_by_user_id (user_id: INTEGER): detachable LIST [GRAPH]
			-- retrive all graphs from db by user_id
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			create {ARRAYED_LIST [GRAPH]} last_retrieve_all_result.make (0)

				-- Query the contents of the Example table
			create l_query.make ("SELECT graph_id,description,title,content FROM GRAPHS WHERE user_id = :USER_ID;", db_mgr)
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
					if attached last_retrieve_all_result as lrq then
						lrq.force (l_graph)
					end
				end, [create {SQLITE_INTEGER_ARG}.make (":USER_ID", user_id)])
			Result := last_retrieve_all_result
		end

feature -- Update

	update (a_graph: GRAPH; user_id: INTEGER)
			-- update a graph with `a_graph' for the user with id `user_id'
		local
			l_update: SQLITE_MODIFY_STATEMENT
			l_descr_arg: SQLITE_BIND_ARG [ANY]
			l_title_arg: SQLITE_BIND_ARG [ANY]
		do
				-- Create an update statement with variables

			create l_update.make ("UPDATE GRAPHS SET description=:DESCRIPTION, title= :TITLE, content= :CONTENT WHERE graph_id= :ID and user_id = :USER_ID;", db_mgr)
			check
				l_update_is_compiled: l_update.is_compiled
			end
				-- Commit handling
			db_mgr.begin_transaction (False)
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
			l_update.execute_with_arguments ([l_descr_arg, l_title_arg, create {SQLITE_STRING_ARG}.make (":CONTENT", a_graph.content), create {SQLITE_INTEGER_ARG}.make (":ID", a_graph.id), create {SQLITE_INTEGER_ARG}.make (":USER_ID", user_id)])
				-- Commit changes
			db_mgr.commit
		end

feature -- Insert

	insert (a_graph: GRAPH; user_id: INTEGER)
			-- insert a new graph `a_graph' for the user user_id
		local
			l_insert: SQLITE_INSERT_STATEMENT
			l_descr_arg: SQLITE_BIND_ARG [ANY]
			l_title_arg: SQLITE_BIND_ARG [ANY]
		do
				-- Create a insert statement with variables
			create l_insert.make ("INSERT INTO GRAPHS (description,title,content,user_id) VALUES (:DESCRIPTION, :TITLE, :CONTENT, :USER_ID);", db_mgr)
			check
				l_insert_is_compiled: l_insert.is_compiled
			end

				-- Commit handling
			db_mgr.begin_transaction (False)
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
			l_insert.execute_with_arguments ([l_descr_arg, l_title_arg, create {SQLITE_STRING_ARG}.make (":CONTENT", a_graph.content), create {SQLITE_INTEGER_ARG}.make (":USER_ID", user_id)])

				-- Commit changes
			last_row_id := l_insert.last_row_id
			db_mgr.commit
		end

feature -- Delete

	delete_by_id (an_id: INTEGER; user_id: INTEGER)
			-- delte a row with ID `an_id' from db
		local
			l_delete: SQLITE_MODIFY_STATEMENT
		do
				-- Create a DELETE statement with variables
			create l_delete.make ("DELETE FROM GRAPHS WHERE graph_id = :ID and user_id = :USER_ID;", db_mgr)
			check
				l_delete_is_compiled: l_delete.is_compiled
			end

				-- Commit handling
			db_mgr.begin_transaction (False)
			l_delete.execute_with_arguments ([create {SQLITE_INTEGER_ARG}.make (":ID", an_id), create {SQLITE_INTEGER_ARG}.make (":USER_ID", user_id)])

				-- Commit changes
			db_mgr.commit
		end

feature -- DB handler

	db_mgr: SQLITE_DATABASE
		do
			if attached imp_db_mgr as l_db_mgr then
				Result := l_db_mgr
			else -- default implementation db
				Result := db
			end
		end

	set_up_db_mgr (a_db: SQLITE_DATABASE)
		do
			imp_db_mgr := a_db
		end

feature {NONE} -- Implementation

	last_retrieve_all_result: detachable LIST [GRAPH]

	last_retrieve_page_result: detachable LIST [GRAPH]

	last_retrieve_by_id_result: detachable GRAPH

	last_integer_count : INTEGER

	imp_db_mgr: detachable SQLITE_DATABASE

end
