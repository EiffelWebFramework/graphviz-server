note
	description: "Summary description for {SERVER_TEST}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SERVER_TEST
inherit
	GRAPHVIZ_SERVER
		redefine
			launch
		end
create {GRAPHVIZ_SERVER} make

feature -- Access
	port_number : INTEGER
	base_url : STRING = ""
feature -- Launch
	launch (a_service: WSF_SERVICE; opts: detachable WSF_SERVICE_LAUNCHER_OPTIONS)
		local
			l_launcher: WSF_DEFAULT_SERVICE_LAUNCHER
			app: NINO_SERVICE
			wt: WORKER_THREAD
			e: EXECUTION_ENVIRONMENT
		do
			port_number := 0
			create app.make_custom (a_service.to_wgi_service, "")
			web_app := app

			create wt.make (agent app.listen (port_number))
			wt.launch
			create e
			e.sleep (1_000_000_000 * 5)
			port_number := app.port
--			create l_launcher.make_and_launch (a_service, opts)
		end

feature -- Shutdown
	shutdown
		do
			if attached web_app as app then
				app.shutdown
			end
		end

feature -- Access
	web_app: detachable NINO_SERVICE
end
