note
	description: "Summary description for {USER}."
	date: "$Date$"
	revision: "$Revision$"

class
	USER

create
	make

feature -- Initialization

	make (an_user_name: STRING_32; a_password: STRING_32)
		do
			set_user_name (an_user_name)
			set_password (a_password)
		end

feature -- Access

	id: INTEGER

	user_name: STRING_32

	password: STRING_32

feature --	Change Element

	set_id (an_id: INTEGER)
			-- Set user id with `an_id'
		do
			id := an_id
		ensure
			id_setted: id ~ an_id
		end

	set_user_name (an_user_name: STRING_32)
			-- Set user user_name with `an_user_name'
		do
			user_name := an_user_name
		ensure
			user_name_setted: user_name ~ an_user_name
		end

	set_password (a_password: STRING_32)
			-- Set user password with `a_password'
		do
			password := a_password
		ensure
			user_password_setted: password ~ a_password
		end

end
