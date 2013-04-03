note
	description: "Summary description for {SEARCH_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SEARCH_HANDLER

inherit

	WSF_URI_HANDLER
		rename
			execute as uri_execute,
			new_mapping as new_uri_mapping
		end

	WSF_URI_TEMPLATE_HANDLER
		rename
			execute as uri_template_execute,
			new_mapping as new_uri_template_mapping
		select
			new_uri_template_mapping
		end

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get
		end

	COLLECTION_JSON_HELPER

	SHARED_DATABASE_API

	REFACTORING_HELPER


feature -- Initialization



feature -- execute

	uri_execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (req, res)
		end

	uri_template_execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute request handler
		do
			execute_methods (req, res)
		end

feature -- HTTP Methods


	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found and their corresponding error in collection json
		local
			l_graphs : detachable LIST[GRAPH]
		do
			if attached req.query_parameter ("search") as l_query_parameter then
				if l_query_parameter.is_string and then attached l_query_parameter.as_string.value as l_value then
					if attached graph_dao.retrieve_all_by_title (l_value) as graphs and then attached {CJ_COLLECTION} collection_json_graph (req, Void) as l_cj then
						across
							graphs as ic
						loop
							build_item (req, ic.item, l_cj)
						end
						if attached json.value (l_cj) as l_cj_answer then
							compute_response_get (req, res, l_cj_answer.representation, {HTTP_STATUS_CODE}.ok)
						end
					end
				end
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; msg: STRING; status_code: INTEGER)
		local
			h: HTTP_HEADER
			l_msg: STRING
		do
			create h.make
			h.put_content_type ("application/vnd.collection+json")
			h.add_header_key_value ("Access-Control-Allow-Origin","*")
			l_msg := msg
			h.put_content_length (l_msg.count)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code (status_code)
			res.put_header_text (h.string)
			res.put_string (l_msg)
		end


end
