note
	description: "[
		Eiffel tests that can be executed by testing tool.
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	GRAPH_MANAGER_TEST_SET

inherit

	EQA_TEST_SET
		redefine
			on_prepare
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
			create user_mgr
			create graph_mgr
			user_mgr.set_up_db_mgr (db_test ("graph_test.sqlite"))
			graph_mgr.set_up_db_mgr (db_test ("graph_test.sqlite"))
		end

feature -- Test routines

	test_add_graph
			-- New test routine
		local
			user: USER
			graph: GRAPH
		do
			create user.make ("jv", "test123")
			user_mgr.insert (user)
			assert ("Expected 1", user_mgr.last_row_id = 1)
			create graph.make ("digraph{A ->B}", "Simple graph", "Graphviz example")
			graph_mgr.insert (graph, 1);
			if attached graph_mgr.retrieve_by_id_and_user_id (1, 1) as l_grp then
				assert ("Content", l_grp.content ~ "digraph{A ->B}")
				assert ("Title", l_grp.title ~ "Simple graph")
				assert ("Description", l_grp.description ~ "Graphviz example")
			end
		end

feature --{NONE} Implementation

	user_mgr: USER_MANAGER

	graph_mgr: GRAPH_MANAGER

end
