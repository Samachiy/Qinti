extends Node

onready var server = $ServerInterface
onready var downloader = $Downloader

const STATE_LOADING = Consts.SERVER_STATE_LOADING
const STATE_GENERATING = Consts.SERVER_STATE_GENERATING
const STATE_DOWNLOADING = Consts.SERVER_STATE_DOWNLOADING
const STATE_READY = Consts.SERVER_STATE_READY
const STATE_STARTING = Consts.SERVER_STATE_STARTING
const STATE_PREPARING_DEPENDENCIES = Consts.SERVER_STATE_PREPARING_DEPENDENCIES
const STATE_PREPARING_PYTHON = Consts.SERVER_STATE_PREPARING_PYTHON
const STATE_INSTALLING = Consts.SERVER_STATE_INSTALLING
const STATE_SHUTDOWN = Consts.SERVER_STATE_SHUTDOWN

const FEATURE_CONTROLNET = "controlnet"
const FEATURE_IMAGE_INFO = "image_info"
const FEATURE_IMG_TO_IMG = "img_to_img"
const FEATURE_INPAINT_OUTPAINT = "inpaint_outpaint"
const FEATURE_REGIONAL_PROMPTING = "regional_prompting"

const MSG_NO_FEATURE_GENERIC = "MESSAGE_NO_FEATURE_GENERIC"
const MSG_NO_FEATURE_CONTROLNET = "MESSAGE_NO_FEATURE_CONTROLNET"

var features: FeatureList = FeatureList.new()

var api: DiffusionAPI = null
var server_urls = [
	"http://127.0.0.1:7860",
	"http://127.0.0.1:7861",
	"http://127.0.0.1:7862",
]

var server_address: ServerAddress = null
var controlnet_models = null
var diffusion_models = null
var samplers = null
var upscalers = null
var retrieving_start_info: bool = false
var _state = STATE_LOADING setget set_state, get_state
var last_gen_response_object: Object = null
var last_gen_response_method: String = ""
var last_gen_data: Dictionary = {}
var generation_request: APIRequest = null
var running_repo: LocalRepo = null

var sequences_data = {}

signal controlnet_models_refreshed
signal local_controlnet_models_refreshed
signal diffusion_models_refreshed(success)
signal samplers_refreshed
signal upscalers_refreshed
signal paths_refreshed
signal server_ready
signal state_changed(previous_state, next_state)


func _ready():
	Roles.request_role(self, Consts.ROLE_DIFFUSION_SERVER)
	Roles.request_role_on_roles_cleared(self, Consts.ROLE_DIFFUSION_SERVER)
	Director.connect_global_save_cues_requested(self, "_on_global_save_cues_requested")


func set_state(value: String):
	if value == _state:
		return
	
	var prev_state = _state
	_state = value
	emit_signal("state_changed", prev_state, _state)


func get_state():
	return _state


func is_api_initialized():
	if api != null and server_address != null:
		return true
	else:
		return false


func connect_feature(feature_name: String, target_object: Object, target_method: String):
	features.connect_toggle_feature(feature_name, target_object, target_method)


func instance_api(api_script: GDScript) -> DiffusionAPI:
	var new_api = api_script.new()
	if not new_api is DiffusionAPI:
		return null
	
	add_child(new_api)
	
	if api != null:
		remove_child(api)
	
	api = new_api
	var e = api.connect("data_refreshed", self, "_on_data_refreshed")
	e = api.connect("paths_refreshed", self, "_on_paths_refreshed")
	l.error(e, l.CONNECTION_FAILED)
	Roles.request_role(api, "API", true)
	Roles.request_role_on_roles_cleared(api, "API")
	
	return api

func refresh_data(what: String):
	if not is_api_initialized():
		return
	
	api.refresh_data(what)


func _on_paths_refreshed():
	emit_signal("paths_refreshed")


func _on_data_refreshed(what_dict: Dictionary):
	l.g("Refreshed following server data: " + str(what_dict), l.INFO)
	
	if what_dict.get(DiffusionAPI.REFRESH_SAMPLERS, false):
		emit_signal("samplers_refreshed")
	
	if what_dict.get(DiffusionAPI.REFRESH_UPSCALERS, false):
		emit_signal("upscalers_refreshed")
	
	if what_dict.get(DiffusionAPI.REFRESH_CONTROLNET_MODELS, false):
		emit_signal("controlnet_models_refreshed")
	
	if what_dict.get(DiffusionAPI.REFRESH_CONTROLNET_MODELS_LOCAL, false):
		emit_signal("local_controlnet_models_refreshed")
	
	if DiffusionAPI.REFRESH_MODELS in what_dict:
		emit_signal("diffusion_models_refreshed", what_dict.get(DiffusionAPI.REFRESH_MODELS))
	
	if retrieving_start_info:
		emit_signal("server_ready")
		set_state(STATE_READY)
		retrieving_start_info = false


func search_controlnet_model(search_string: String):
	if controlnet_models == null:
		return ''
	
	search_string = search_string.to_lower()
	for model_name in controlnet_models:
		if model_name is String and search_string in model_name.to_lower():
			return model_name
	
	return '' # if it reaches this point, that means the search failed


func _on_ServerInterface_server_check_succeeded():
	controlnet_models = null
	diffusion_models = null
	samplers = null
	upscalers = null
	retrieving_start_info = true
	api.refresh_data(DiffusionAPI.REFRESH_ALL)


func initialize_server_connection():
	# Will first check for the server, if it doesn't exist, it will initialize it
	server.initialize_connection(server_urls, api)
	server_address = server.current_server_address


func wait_for_server_connection():
	# Will first check for the server, if it doesn't exist, it will initialize it
	server.wait_for_connection(server_urls, api)
	server_address = server.current_server_address


func regenerate():
	if api == null:
		return
	
	if not last_gen_data.empty():
		if last_gen_response_object != null and not last_gen_response_method.empty():
			generate(last_gen_response_object, last_gen_response_method, last_gen_data)


func _on_generation_failed(_result):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
			Consts.HELP_DESC_IMAGE_GEN_FAILED]).execute()
	cancel_diffusion()
	cancel_download()
	set_state(STATE_READY)
	l.g("Image generation failed. Parameters: " + 
			str(api.get_request_data_no_images_no_prompts(last_gen_data)))


func preprocess(response_object: Object, response_method: String, image_data: ImageData, 
preprocessor_name: String):
	if not is_api_initialized():
		return
	
	api.preprocess(response_object, response_method, image_data, preprocessor_name)


func generate(response_object: Object, response_method: String, custom_gen_data: Dictionary = {}):
	if not is_api_initialized():
		return
	
	last_gen_response_object = response_object
	last_gen_response_method = response_method
	# The next code notifies the server_state_indicator for a state change
	set_state(Consts.SERVER_STATE_GENERATING)
	
	generation_request = api.generate(response_object, response_method, custom_gen_data)
	Python.add_next_line()
	last_gen_data = api.request_data.duplicate(true)


func request_image_info(response_object: Object, response_method: String, image_base64: String):
	if not is_api_initialized():
		return
	
	api.request_image_info(response_object, response_method, image_base64)


func request_progress(response_object: Object, response_method: String):
	if not is_api_initialized():
		return
	
	api.request_progress(response_object, response_method)


func get_current_diffusion_model(response_object: Object, response_method: String):
	if not is_api_initialized():
		return
	
	api.get_current_diffusion_model(response_object, response_method)


func set_server_diffusion_model(model_file_name: String, response_object: Object, 
success_method: String, failure_method: String):
	if not is_api_initialized():
		return
	
	api.set_server_diffusion_model(
			model_file_name, response_object, 
			success_method, failure_method
	)


func cancel_diffusion():
	if not is_api_initialized():
		return
	
	api.cancel_diffusion()


func _on_diffusion_canceled(_result):
	# It's not necessary to stop the loading icon since server_state_indicator.gd 
	# will automatically change to SERVER_READY if the job is succesfully stopped
	# which in turn will stop the loading icon
	if is_instance_valid(generation_request):
		generation_request.terminate()
	else:
		# if there was not image being generated, however, we do need to add ready
		DiffusionServer.set_state(Consts.SERVER_STATE_READY)


func cancel_download():
	downloader.cancel_all_downloads()


func load_servers_data(cue: Cue):
	sequences_data = cue.get_at(0, {})


func _on_global_save_cues_requested():
	Director.add_global_save_cue(Consts.ROLE_DIFFUSION_SERVER, "load_servers_data", [
		sequences_data
	])







## DEPRECATED unless api endpoint does something in a future update
#func refresh_diffusion_models(_result):
#	# REMOTE server behaviour may be different
#	# We take an argument since if we have already loaded the models, then a refresh
#	# request means that we also need to refresh the models server side and then
#	# refresh locally.
#	if not is_api_initialized():
#		return
#
#	var api_request
#	var url
#	if diffusion_models == null:
#		api_request = APIRequest.new(self, "_on_diffusion_models_refreshed", api)
#		url = server_address.url + api.ADDRESS_GET_DIFFUSION_MODEL_LIST
#		api_request.api_get(url)
#	else:
#		api_request = APIRequest.new(self, "refresh_diffusion_models", api)
#		api_request.connect_on_request_failed(self, "refresh_diffusion_models")
#		diffusion_models = null
#		url = server_address.url + api.ADDRESS_REFRESH_DIFFUSION_MODELS
#		api_request.api_post(url, {})
#
#
#func _on_diffusion_models_refreshed(result):
#	var success = result is Array and not result.empty()
#	if success:
#		diffusion_models = {}
#	else:
#		l.g("Couldn't retrieve the diffusion models")
#		diffusion_models = null
#		return
#
#	var model_key: String = ''
#	for model_info in result:
#		if model_info is Dictionary:
#			model_key = model_info.get("filename", '')
#			model_key = model_key.get_basename()
#
#		if model_key.empty():
#			continue
#
#		diffusion_models[model_key] = model_info
#
#	emit_signal("diffusion_models_refreshed")
#	if retrieving_start_info:
#		mark_server_ready()


func mark_generation_available():
	if downloader.is_downloading:
		# Downloader will mark server ready by itself
		set_state(STATE_DOWNLOADING)
	else:
		set_state(STATE_READY)
		
