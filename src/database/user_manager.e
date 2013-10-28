note
	description: "Summary description for {USER_MANAGER}."
	date: "$Date$"
	revision: "$Revision$"

class
	USER_MANAGER

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
			sdm_default_create
			set_up_db_mgr (db)
		end

feature -- Access

	last_row_id: INTEGER_64

feature -- Query

	retrieve_by_id (an_id: INTEGER): detachable USER
			-- retrive user by id from db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			last_retrieve_by_id_result := Void

				-- Query the contents of the Example table

			create l_query.make ("SELECT user_id,user_name,password FROM USERS where user_id = :USER_ID;", db)
			check
				l_query_is_compiled: l_query.is_compiled
			end
			l_query.execute_with_arguments (agent  (ia_row: SQLITE_RESULT_ROW): BOOLEAN
				local
					l_user: USER
					l_user_name: detachable STRING_32
					l_password: detachable STRING_32
				do
					if not ia_row.is_null (2) then
						l_user_name := ia_row.string_value (2).to_string_32
					end
					if not ia_row.is_null (3) then
						l_password := ia_row.string_value (3).to_string_32
					end
					if attached l_user_name as l_usr_name and then attached l_password as l_pwd then
						create l_user.make (l_usr_name, l_pwd)
						l_user.set_id (ia_row.integer_value (1))
						last_retrieve_by_id_result := l_user
					end
				end, [create {SQLITE_INTEGER_ARG}.make (":USER_ID", an_id)])
			Result := last_retrieve_by_id_result
		end

	retrieve_by_name_and_password (a_name: STRING; a_password: STRING): detachable USER
			-- retrive user by id from db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			last_retrieve_user_result := Void

				-- Query the contents of the Example table

			create l_query.make ("SELECT user_id,user_name,password FROM USERS where user_name = :USER_NAME and password = :PASSWORD;", db)
			check
				l_query_is_compiled: l_query.is_compiled
			end
			db.begin_transaction (False)
			l_query.execute_with_arguments (agent  (ia_row: SQLITE_RESULT_ROW): BOOLEAN
				local
					l_user: USER
					l_user_name: detachable STRING_32
					l_password: detachable STRING_32
				do
					if not ia_row.is_null (2) then
						l_user_name := ia_row.string_value (2).to_string_32
					end
					if not ia_row.is_null (3) then
						l_password := ia_row.string_value (3).to_string_32
					end
					if attached l_user_name as l_usr_name and then attached l_password as l_pwd then
						create l_user.make (l_usr_name, l_pwd)
						l_user.set_id (ia_row.integer_value (1))
						last_retrieve_user_result := l_user
					end
				end, [create {SQLITE_STRING_ARG}.make (":USER_NAME", a_name), create {SQLITE_STRING_ARG}.make (":PASSWORD", a_password)])
			Result := last_retrieve_user_result
			db.commit
		end

	exist_user_name (an_user_name: STRING): BOOLEAN
			-- retrive user by id from db
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
				-- clean all the previous results
			exist_user := False

				-- Query the contents of the Example table

			db.begin_transaction (False)
			create l_query.make ("SELECT COUNT(*) FROM USERS where user_name = :USER_NAME;", db)
			check
				l_query_is_compiled: l_query.is_compiled
			end
			l_query.execute_with_arguments (agent  (ia_row: SQLITE_RESULT_ROW): BOOLEAN
				local
					l_count: INTEGER
				do
					l_count := ia_row.integer_value (1)
					exist_user := l_count /= 0
				end, [create {SQLITE_STRING_ARG}.make (":USER_NAME", an_user_name)])
			Result := exist_user
			db.commit
		end

feature -- Update

	update (a_user: USER)
			-- update a user with `a_user'
		local
			l_update: SQLITE_MODIFY_STATEMENT
			l_user_name_arg: SQLITE_BIND_ARG [ANY]
			l_password_arg: SQLITE_BIND_ARG [ANY]
		do
				-- Create an update statement with variables

			create l_update.make ("UPDATE USERS SET user_name=:USER_NAME, password= :PASSWORD WHERE  user_id = :USER_ID;", db_mgr)
			check
				l_update_is_compiled: l_update.is_compiled
			end
				-- Commit handling
			db_mgr.begin_transaction (False)
			create {SQLITE_STRING_ARG} l_user_name_arg.make (":USER_NAME", a_user.user_name)
			create {SQLITE_STRING_ARG} l_password_arg.make (":PASSWORD", a_user.password)
			l_update.execute_with_arguments ([l_user_name_arg, l_password_arg, create {SQLITE_INTEGER_ARG}.make (":USER_ID", a_user.id)])
				-- Commit changes
			db_mgr.commit
		end

feature -- Insert

	insert (a_user: USER)
			-- insert a new user `a_user'
		require
			user_name_unique: not exist_user_name (a_user.user_name)
		local
			l_insert: SQLITE_INSERT_STATEMENT
			l_user_name_arg: SQLITE_BIND_ARG [ANY]
			l_password_arg: SQLITE_BIND_ARG [ANY]
		do
				-- Create a insert statement with variables
			create l_insert.make ("INSERT INTO USERS (user_name,password) VALUES (:USER_NAME, :PASSWORD);", db_mgr)
			check
				l_insert_is_compiled: l_insert.is_compiled
			end

				-- Commit handling
			db_mgr.begin_transaction (False)
			create {SQLITE_STRING_ARG} l_user_name_arg.make (":USER_NAME", a_user.user_name)
			create {SQLITE_STRING_ARG} l_password_arg.make (":PASSWORD", a_user.password)
			l_insert.execute_with_arguments ([l_user_name_arg, l_password_arg])

				-- Commit changes
			last_row_id := l_insert.last_row_id
			db_mgr.commit
		ensure
			user_name_exist: exist_user_name (a_user.user_name)
		end

feature -- Delete

	delete_by_id (user_id: INTEGER)
			-- delte a row with ID `an_id' from db_mgr, and all his
			-- dependent grahps
		local
			l_delete_graphs: SQLITE_MODIFY_STATEMENT
			l_delete_user: SQLITE_MODIFY_STATEMENT
		do
				-- Create a DELETE statement with variables

			create l_delete_graphs.make ("DELETE FROM GRAPHS WHERE user_id = :USER_ID;", db_mgr)
			check
				l_delete_is_compiled: l_delete_graphs.is_compiled
			end
				-- Create a DELETE statement with variables
			create l_delete_user.make ("DELETE FROM USERS WHERE user_id = :USER_ID;", db_mgr)
			check
				l_delete_is_compiled: l_delete_user.is_compiled
			end

				-- Commit handling
			db_mgr.begin_transaction (False)
			l_delete_graphs.execute_with_arguments ([create {SQLITE_INTEGER_ARG}.make (":USER_ID", user_id)])
			l_delete_user.execute_with_arguments ([create {SQLITE_INTEGER_ARG}.make (":USER_ID", user_id)])
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

	last_retrieve_by_id_result: detachable USER

	last_retrieve_user_result: detachable USER

	imp_db_mgr: detachable SQLITE_DATABASE

	exist_user: BOOLEAN

end
