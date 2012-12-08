note
	description: "[
		Eiffel tests that can be executed by testing tool.
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	USER_MANAGER_TEST_SET

inherit
	EQA_TEST_SET
		redefine
			on_prepare,
			on_clean
		select
			default_create
		end
	SHARED_DATABASE_MANAGER
		rename
			default_create as sdm_default_create
		end

feature -- Events		
	on_prepare
			-- Called after all initializations in `default_create'.
		do
			create  user_mgr
	        create  graph_mgr
	        user_mgr.set_up_db_mgr (db_test("user_test.sqlite"))
			graph_mgr.set_up_db_mgr (db_test("user_test.sqlite"))
		end

	on_clean

		do

		end

feature -- Test routines



	test_add_user
		local
			user : USER
		do
			create user.make ("jv", "test007")
			user_mgr.insert (user)
			assert ("Expected id 1", user_mgr.last_row_id  = 1)
		end

	test_retrive_user
		local
			user : USER
		do
			create user.make ("jv", "test007")
			user_mgr.insert (user)
			assert ("Expected id 1", user_mgr.last_row_id  = 1)
			create user.make ("joe", "test007")
			user_mgr.insert (user)
			assert ("Expected id 2", user_mgr.last_row_id = 2)
			if attached user_mgr.retrieve_by_id (2) as usr_2 then
				assert("User id 2", usr_2.id = 2)
				assert("User name", usr_2.user_name ~ "joe")
				assert("User password", usr_2.password ~ "test007")
			end
		end

	test_update_user
		local
			user : USER
		do
			create user.make ("jv", "test007")
			user_mgr.insert (user)
			assert ("Expected id 1", user_mgr.last_row_id = 1)
			create user.make ("joe", "test007")
			user_mgr.insert (user)
			assert ("Expected id 2", user_mgr.last_row_id = 2)
			if attached user_mgr.retrieve_by_id (2) as usr_2 then
				usr_2.set_password ("pwd123")
				user_mgr.update (usr_2)
			end

			if attached user_mgr.retrieve_by_id (2) as usr_2 then
				assert("User id 2", usr_2.id = 2)
				assert("User name", usr_2.user_name ~ "joe")
				assert("User password", usr_2.password ~ "pwd123")
			end

		end

		test_delete_user
			local
				user : USER
			do
				create user.make ("jv", "test007")
				 user_mgr.insert (user)
				assert ("Expected id 1", user_mgr.last_row_id = 1)
				create user.make ("joe", "test007")
				user_mgr.insert (user)
				assert ("Expected id 2", user_mgr.last_row_id = 2)
				user_mgr.delete_by_id (2)
				assert("Expected Void", user_mgr.retrieve_by_id (2)= Void)
			end

		test_user_and_graphs
			--two users, user 1, 2 graphs
			--user 2, 1 graph, total graphs 3
			local
				user : USER
				graph : GRAPH
			do
				create user.make ("jv", "pwd123")
				-- Store user jv
				user_mgr.insert (user)
				assert ( "Ëxpected 1", user_mgr.last_row_id = 1)

				-- store 2 graphs related to jv
			    create graph.make ("digraph{A->B}", "AB", "Example1");
			    graph_mgr.insert (graph, 1);
			    create graph.make ("digraph{C->D}", "CD", "Example2");
				graph_mgr.insert (graph, 1);

				-- store user jf
				create user.make ("jf", "pwd123")
				user_mgr.insert (user)
				assert ( "Ëxpected 2", user_mgr.last_row_id = 2)

				-- store 1 graph related to jf
 				create graph.make ("digrgraph{E->F}", "EF", "Example3");
				graph_mgr.insert (graph, 2);

				-- Verfify the number of graph in the db
				if attached graph_mgr.retrieve_all as l_graphs_all then
					assert("Expected 3 elements", l_graphs_all.count = 3)
				end

				-- Verify the number of graph user "jv"
				if attached graph_mgr.retrieve_all_by_user_id (1) as l_graphs_user_jv then
					assert("Expected 2 elements", l_graphs_user_jv.count = 2)
				end


				-- Verify the number of graph user "jf"
				if attached graph_mgr.retrieve_all_by_user_id (2) as l_graphs_user_jf then
					assert("Expected 1 elements", l_graphs_user_jf.count = 1)
				end


			end

		test_user_and_graphs_delete_by_user
				--given two users, user 1, 2 graphs
				--user 2, 1 graph, total graphs 3
				-- when delete user 1, assert : 1 user, 1 graph
				local
					user : USER
					graph : GRAPH
				do
					create user.make ("jv", "pwd123")
					-- Store user jv
					user_mgr.insert (user)
					assert ( "Ëxpected 1", user_mgr.last_row_id = 1)

					-- store 2 graphs related to jv
				    create graph.make ("digraph{A->B}", "AB", "Example1");
				    graph_mgr.insert (graph, 1);
				    create graph.make ("digraph{C->D}", "CD", "Example2");
					graph_mgr.insert (graph, 1);

					-- store user jf
					create user.make ("jf", "pwd123")
					user_mgr.insert (user)
					assert ( "Ëxpected 2", user_mgr.last_row_id = 2)

					-- store 1 graph related to jf
	 				create graph.make ("digrgraph{E->F}", "EF", "Example3");
					graph_mgr.insert (graph, 2);

					-- Verfify the number of graph in the db
					if attached graph_mgr.retrieve_all as l_graphs_all then
						assert("Expected 3 elements", l_graphs_all.count = 3)
					end

					-- Verify the number of graph user "jv"
					if attached graph_mgr.retrieve_all_by_user_id (1) as l_graphs_user_jv then
						assert("Expected 2 elements", l_graphs_user_jv.count = 2)
					end


					-- Verify the number of graph user "jf"
					if attached graph_mgr.retrieve_all_by_user_id (2) as l_graphs_user_jf then
						assert("Expected 1 elements", l_graphs_user_jf.count = 1)
					end

					-- delete user 1
					user_mgr.delete_by_id (1)

					-- verify user does not exist anymore
					assert ("Expected Void", user_mgr.retrieve_by_id (1) = Void)

					-- verify the number of total graphs
					if attached graph_mgr.retrieve_all as l_graphs_all  then
						assert("Expected 1 graph", l_graphs_all.count = 1)
					end


				end
feature
		user_mgr : USER_MANAGER
		graph_mgr : GRAPH_MANAGER
end


