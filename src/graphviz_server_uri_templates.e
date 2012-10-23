note
	description: "Summary description for {GRAPHVIZ_SERVER_URI_TEMPLATES}."
	date: "$Date$"
	revision: "$Revision$"

class
	GRAPHVIZ_SERVER_URI_TEMPLATES

feature -- Access: collection	

	home_uri: STRING = "/"

	graph_uri: STRING = "/graph"

	user_uri: STRING = "/user"

feature -- Access: graph	

	graph_id_type_uri_template: URI_TEMPLATE
		once
			create Result.make (graph_uri + "/{id}.{type}")
		end

	graph_id_uri_template: URI_TEMPLATE
		once
			create Result.make (graph_uri + "/{id}")
		end

	graph_id_type_uri (a_id: like {GRAPH}.id; a_type: READABLE_STRING_GENERAL): STRING_8
		local
			ht: HASH_TABLE [detachable ANY, STRING_8]
		do
			create ht.make (2)
			ht.force (a_id, "id")
			ht.force (a_type, "type")
			Result := graph_id_type_uri_template.expanded_string (ht)
		end

	graph_id_uri (a_id: like {GRAPH}.id): STRING_8
		local
			ht: HASH_TABLE [detachable ANY, STRING_8]
		do
			create ht.make (1)
			ht.force (a_id, "id")
			Result := graph_id_uri_template.expanded_string (ht)
		end

end
