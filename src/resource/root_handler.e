note
	description: "Summary description for {ROOT_HANDLER}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	ROOT_HANDLER

inherit

	WSF_URI_HANDLER
		rename
			execute as uri_execute,
			new_mapping as new_uri_mapping
		end

	WSF_RESOURCE_HANDLER_HELPER
		redefine
			do_get
		end

	SHARED_EJSON

	REFACTORING_HELPER

	COLLECTION_JSON_HELPER

	WSF_SELF_DOCUMENTED_HANDLER

feature -- Documentation

	mapping_documentation (m: WSF_ROUTER_MAPPING): WSF_ROUTER_MAPPING_DOCUMENTATION
		do
			create Result.make (m)
			Result.add_description ("Main entry point")
		end

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

feature --HTTP Methods

	do_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Using GET to retrieve resource information.
			-- If the GET request is SUCCESS, we response with
			-- 200 OK, and a representation of the root collection JSON
			-- If the GET request is not SUCCESS, we response with
			-- 404 Resource not found
		do
			if attached req.orig_path_info as orig_path then
				compute_response_get (req, res)
			end
		end

	compute_response_get (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			h: HTTP_HEADER
			l_msg: STRING
		do
			create h.make
		    --| What about to create HTTP_VENDOR_CONTENT_TYPES?
		    --| Maybe we can provide a facility to register new vendor content types.
			h.put_content_type ("application/vnd.collection+json")
			l_msg := collection_json_root (req)
			h.put_content_length (l_msg.count)
			if attached req.request_time as time then
				h.put_utc_date (time)
			end
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (l_msg)
		end

note
	copyright: "2011-2012, Javier Velilla and others"
	license: "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"

end
