extends Node

# POSTRELEASE some functions must be moved to the api, like checking the config contents

# Boot up process
# 1. Check server, but immeddiately cicling the urls
# 2. If that fails, start server (via the pending restart function)
# 3. Start the timer and check again every 2 seconds, cycling urls 
# 4. Once server connects, it will return the config, if the server it's not configured
#		we call config server, if the call fails, we attempt again

const CONTROLNET_MAX_MODELS_NUM = "control_net_max_models_num"
const RECOMMENDED_MODELS_NUM = 10

onready var timer = $TimerProbe

var current_server_address: ServerAddress = null
var api: DiffusionAPI = null
var start_if_probe_failure: bool = false
var pending_restart: bool = false

signal server_signaled_shutdown
signal server_check_succeeded
signal server_stopped


func initialize_connection(server_urls: Array, server_api: DiffusionAPI):
	if server_api == null:
		l.g("Can't initialize server, API is null. URLs: " + str(server_urls))
		return
	
	set_server_address(server_urls)
	if current_server_address == null:
		l.g("Failure to initialize server")
		return 
	
	set_api(server_api)
	l.g("Initializing server with API: " + get_api_name(), l.INFO)
	DiffusionServer.set_state(Consts.SERVER_STATE_LOADING)
	start_if_probe_failure = true
	api.probe_server(current_server_address)
	DiffusionServer.set_state(Consts.SERVER_STATE_LOADING) 


func wait_for_connection(server_urls: Array, server_api: DiffusionAPI):
	if server_api == null:
		l.g("Can't wait for server, API is null. URLs: " + str(server_urls))
		return
	
	set_server_address(server_urls)
	if current_server_address == null:
		l.g("Failure to wait for server")
		return 
	
	set_api(server_api)
	l.g("Waiting for server with API: " + get_api_name(), l.INFO)
	start_if_probe_failure = false
	api.probe_server(current_server_address)
	DiffusionServer.set_state(Consts.SERVER_STATE_LOADING) 


func set_server_address(server_urls: Array):
	current_server_address = ServerAddress.new(server_urls)


func set_api(server_api: DiffusionAPI):
	DiffusionServer.features.reset_all()
	api = server_api
	var e = api.connect("server_probed", self, "_on_server_probed")
	l.error(e, l.CONNECTION_FAILED)
	e = api.connect("server_adjusted", self, "_on_server_adjusted")
	l.error(e, l.CONNECTION_FAILED)
	e = api.connect("server_stopped", self, "_on_server_stopped")
	l.error(e, l.CONNECTION_FAILED)


func _on_server_probed(success: bool):
	if success:
		Python.start_listening()
		api.adjust_server()
		return
	
	# If prove failure, do this:
	if current_server_address.is_last_url() and start_if_probe_failure:
		start_if_probe_failure = false
		start_server()
	else:
		timer.start()


func _on_server_adjusted(_success: bool):
	l.g(str(api.config_report), l.INFO)
	emit_signal("server_check_succeeded")


func _on_server_stopped():
	l.g("Server stopped signal received", l.INFO)
	emit_signal("server_stopped")
	if pending_restart:
		pending_restart = false
		start_server()


func restart_server():
	if not _is_api_loaded("Restart"):
		return
	
	pending_restart = true
	api.stop_server()


func start_server():
	if not _is_api_loaded("Start"):
		return
	
	Cue.new(Consts.ROLE_SERVER_MANAGER, "start_server").execute()
	start_if_probe_failure = false
	api.probe_server(current_server_address)
	DiffusionServer.set_state(Consts.SERVER_STATE_LOADING) 


func stop_server():
	if not _is_api_loaded("Shutdown"):
		call_deferred("emit_signal", "server_stopped")
		# There wasn't even a server in the first place
		return self
	
	emit_signal("server_signaled_shutdown")
	api.call_deferred("stop_server")
	return self


func get_api_name() -> String:
	if api is DiffusionAPI:
		var api_name: String = api.get_script().resource_path
		api_name = api_name.to_lower().get_file().get_basename()
		api_name = api_name.replace('api', '')
		api_name = api_name.capitalize().replace(' ', '')
		return api_name
	else:
		return ''


func _on_Timer_timeout():
	timer.stop()
	current_server_address.cycle_next_url()
	api.probe_server(current_server_address) 
	DiffusionServer.set_state(Consts.SERVER_STATE_LOADING) 


func _is_api_loaded(current_step: String):
	if api == null:
		l.g("No api was found in ServerInterface, please initialize it properly. Step '" +
				current_step + "' aborted.")
		return false
	
	if current_server_address == null:
		l.g("The server address is not valid. Please set a valid one first. Step '" +
				current_step + "' aborted.")
		return false
	
	return true


#func check_server(start_if_failure: bool = false): # Move to api, turns into probe and verify
#	if not _is_api_loaded("Check"):
#		return
#
#	DiffusionServer.set_state(Consts.SERVER_STATE_LOADING)
#	var api_request = APIRequest.new(self, "_on_server_success", self)
#	api_request.push_server_down_error = false
#	if start_if_failure:
#		api_request.connect_on_request_failed(self, "_on_server_pending_start")
#	else:
#		api_request.connect_on_request_failed(self, "_on_server_failure")
#	var url = current_server_address.url + api.ADDRESS_GET_CONTROLNET_SETTINGS
#	api_request.print_network_error = false
#	api_request.api_get(url)
#
#
#func config_server():
#	if not _is_api_loaded("Configuration"):
#		return
#
#	var api_request = APIRequest.new(self, "_on_config_success", self)
#	api_request.connect_on_request_failed(self, "_on_config_failed")
#	var url = current_server_address.url + api.ADDRESS_SET_SERVER_CONFIG
#	var data = {
#			CONTROLNET_MAX_MODELS_NUM: RECOMMENDED_MODELS_NUM
#		}
#	api_request.api_post(url, data)


#func _on_start_script_failure(): # WHAT
#	timer.stop()
#	l.g("Server crashed unexpectedly, restarting server")
#	start_if_probe_failure = true
#	api.probe_server(current_server_address)
#
#
#func _on_server_success(result):
#	timer.stop()
#	Python.start_listening()
#	var num: int = -1
#	if result is Dictionary:
#		num = int(result.get(CONTROLNET_MAX_MODELS_NUM, -1))
#
#	if num != RECOMMENDED_MODELS_NUM:
#		l.g("Reconfiguring. Server started with configuration: " + str(result), l.WARNING)
#		config_server()
#	else:
#		l.g("Server started with " + str(num) + " available controlnets.")
#		emit_signal("server_check_succeeded")
#		l.g("Server is succesffully running at: " + current_server_address.url, l.INFO)


#func _on_server_failure(_result):
#	timer.start()
#
#
#func _on_config_success(_result):
#	timer.stop()
#	restart_server()


#func _on_config_failed(result: int):
#	if result >= 400 and result <= 505:
#		l.g("The server responds to the configuration request, but the configuration failed." +
#				" Proceeding with current configuration. Error code: " + str(result), l.WARNING)
#		emit_signal("server_check_succeeded")
#		l.g("Server configuration failed, but it is running at: " + 
#				current_server_address.url, l.INFO)
#	else:
#		timer.stop()
#		#config_timer.start()


#func _on_server_pending_restart(_result):
#	l.g("Failure to configure server, attempting again")
#	Cue.new(Consts.ROLE_SERVER_MANAGER, "start_server").execute()
#	timer.start()
#	l.g("Starting server", l.INFO)
#
#
#func _on_server_pending_start(result):
#	if result >= 400 and result <= 505:
#		l.g("The server responds to the check request, but the api call failed." +
#				" Error code: " + str(result), l.WARNING)
#		emit_signal("server_check_succeeded")
#		l.g("Server check failed, but something is running at: " + 
#				current_server_address.url, l.INFO)
#
#	if current_server_address.is_last_url():
#		# If we tried all the urls, we give up and start the server for real
#		_on_server_pending_restart(result)
#	else:
#		# If we still have url to try, we try them immediately
#		current_server_address.cycle_next_url()
#		start_if_probe_failure = true
#		api.probe_server(current_server_address)
		#check_server(true)


#func _on_server_shutdown(_result):
#	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
#			Consts.HELP_DESC_SERVER_SHUTDOWN]).execute()
#	DiffusionServer.set_state(Consts.SERVER_STATE_SHUTDOWN)
#	emit_signal("server_signaled_shutdown")





#func _on_TimerConfig_timeout():
#	timer.stop()
#	config_server()
