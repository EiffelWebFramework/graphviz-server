note
	description: "Summary description for {GRAPH}."
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPH

inherit

	ANY
		redefine
			out
		end

create
	make

feature -- Initialization

	make (a_content: STRING_32; a_title: detachable STRING_32; a_description: detachable STRING_32)
		do
			set_content (a_content)
			set_title (a_title)
			set_description (a_description)
		end

feature -- Access

	content: STRING_32
			--graphviz's code

	id: INTEGER
			--UUID, shortname, integer

	title: detachable STRING_32
			--user friendly title

	description: detachable STRING_32
			--description of the graph

feature -- Change Element

	set_content (a_content: STRING_32)
		do
			content := a_content
		ensure
			set_content: content ~ a_content
		end

	set_title (a_title: detachable STRING_32)
		do
			title := a_title
		ensure
			set_title: title ~ a_title
		end

	set_description (a_description: detachable STRING_32)
		do
			description := a_description
		ensure
			set_description: description ~ a_description
		end

	set_id (a_id: INTEGER)
		do
			id := a_id
		ensure
			set_id: id ~ a_id
		end

feature -- out

	out: STRING
		do
			create Result.make_empty
			Result.append ("%NId : " + id.out + "%N")
			if attached title as l_title then
				Result.append ("%Ntitle : " + l_title + "%N")
			else
				Result.append ("%Ntitle : Null %N")
			end
			if attached description as l_description then
				Result.append ("%Ndescription : " + l_description + "%N")
			else
				Result.append ("%Ndescription : Null %N")
			end
			Result.append ("%Ncontent : " + content + "%N")
		end

end
