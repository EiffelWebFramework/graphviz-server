note
	description: "[
		Example of using GRAPH_MANAGER, INSERT, UPDATE, DELETE and SELECT statements.
		TODO: create test cases
	]"
	legal: ""
	status: ""
	date: ""
	revision: ""

class
	EXAMPLE

create
	make

feature {NONE} -- Initialization
	make
		local
			graph_mgr : GRAPH_MANAGER
		do
			create graph_mgr
			graph_mgr.insert (create {GRAPH}.make("Contenido del grafico", "testing","test de la desc"))
			graph_mgr.insert (create {GRAPH}.make("otro contenido", "testing1",Void))
			graph_mgr.insert (create {GRAPH}.make("tercer contenido", Void,"tercero"))
			if attached  graph_mgr.retrieve_all as all_rows then
				across all_rows as ic loop print (ic.item) end
			end
			print("%N-----------------------%N")
			if attached graph_mgr.retrieve_by_id (3) as item_3 then
				print(item_3)
			end

			graph_mgr.delete_by_id (3)

			print("%N-----------------------%N")
			if attached graph_mgr.retrieve_by_id (3) as item_3 then
				print(item_3)
			else
				print("Item 3 does not exist, was deleted")
			end

	 		if attached graph_mgr.retrieve_by_id (10) as item_10 then
				print(item_10)
				item_10.set_content ("digraph { home -> register; home -> browse}")
				item_10.set_description ("Item modificado")
				item_10.set_title ("No me gustaba el titulo")
				graph_mgr.update (item_10)
			end

			if attached graph_mgr.retrieve_by_id (10) as item_10 then
				print(item_10)
			else
				print("Item 10 does not exist, was deleted")
			end


		end


note
	copyright: "Copyright (c) 1984-2009, Eiffel Software"
	license: "GPL version 2 (see http://www.eiffel.com/licensing/gpl.txt)"
	licensing_options: "http://www.eiffel.com/licensing"
	copying: "[
			This file is part of Eiffel Software's Eiffel Development Environment.
			
			Eiffel Software's Eiffel Development Environment is free
			software; you can redistribute it and/or modify it under
			the terms of the GNU General Public License as published
			by the Free Software Foundation, version 2 of the License
			(available at the URL listed under "license" above).
			
			Eiffel Software's Eiffel Development Environment is
			distributed in the hope that it will be useful, but
			WITHOUT ANY WARRANTY; without even the implied warranty
			of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
			See the GNU General Public License for more details.
			
			You should have received a copy of the GNU General Public
			License along with Eiffel Software's Eiffel Development
			Environment; if not, write to the Free Software Foundation,
			Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
		]"
	source: "[
			Eiffel Software
			5949 Hollister Ave., Goleta, CA 93117 USA
			Telephone 805-685-1006, Fax 805-685-6869
			Website http://www.eiffel.com
			Customer support http://support.eiffel.com
		]"
end
