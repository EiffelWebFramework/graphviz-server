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

	register_uri: STRING = "/register"

	login_uri: STRING = "/login"



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


feature -- Access: user	

	user_id_uri_template: URI_TEMPLATE
		once
			create Result.make (user_uri + "/{id}")
		end

	user_id_uri (a_id: like {USER}.id): STRING_8
		local
			ht: HASH_TABLE [detachable ANY, STRING_8]
		do
			create ht.make (1)
			ht.force (a_id, "id")
			Result := user_id_uri_template.expanded_string (ht)
		end



feature -- Access: user_graphs

	user_graph_uri: URI_TEMPLATE
		once
			create Result.make (user_uri + "/{uid}/graph")
		end


	user_graph_id_type_uri_template: URI_TEMPLATE
		once
			create Result.make (user_graph_uri.template + "/{gid}.{type}")
		end

	user_id_graph_uri (u_id: like {USER}.id): STRING
		local
			ht: HASH_TABLE [detachable ANY, STRING_8]
		do
			create ht.make (1)
			ht.force (u_id, "uid")
			Result := user_graph_uri.expanded_string (ht)
		end


	user_graph_id_uri_template: URI_TEMPLATE
		once
			create Result.make (user_graph_uri.template + "/{gid}")
		end

	user_graph_id_uri (u_id: like {USER}.id;g_id: like {GRAPH}.id): STRING_8
		local
			ht: HASH_TABLE [detachable ANY, STRING_8]
		do
			create ht.make (2)
			ht.force (u_id, "uid")
			ht.force (g_id, "gid")
			Result := user_graph_id_uri_template.expanded_string (ht)
		end


	user_graph_id_type_uri (u_id: like {USER}.id; g_id: like {GRAPH}.id; a_type: READABLE_STRING_GENERAL): STRING_8
		local
			ht: HASH_TABLE [detachable ANY, STRING_8]
		do
			create ht.make (3)
			ht.force (u_id, "uid")
			ht.force (g_id, "gid")
			ht.force (a_type, "type")
			Result := user_graph_id_type_uri_template.expanded_string (ht)
		end


end
