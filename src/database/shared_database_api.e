note
	description: "Summary description for {SHARED_DATABASE_API}."
	date: "$Date$"
	revision: "$Revision$"

class
	SHARED_DATABASE_API

feature -- API

	user_dao: USER_MANAGER
		once
			create Result
		end

	graph_dao: GRAPH_MANAGER
		once
			create Result
		end

end
