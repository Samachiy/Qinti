extends DiffusionAPI

# This api correspond to the family of servers using Automatic1111's web api
# Values extracted from Vladmandic's automatic web ui fork 

class_name AutoWebUI_API

const MAIN_API_CONTEXT = "/sdapi/v1/"
const TEXT2IMG_SERVICE = "txt2img"
const PNG_INFO_SERVICE = "png-info"

const ADDRESS_REFRESH_DIFFUSION_MODELS = "/sdapi/v1/refresh-checkpoints"
const ADDRESS_GET_DIFFUSION_MODEL_LIST = "/sdapi/v1/sd-models"
const ADDRESS_GET_CONTROLNET_MODEL_LIST = "/controlnet/model_list"
const ADDRESS_GET_SAMPLERS = "/sdapi/v1/samplers"
const ADDRESS_GET_UPSCALERS = "/sdapi/v1/upscalers"
const ADDRESS_GET_PROGRESS = "/sdapi/v1/progress?skip_current_image=true"
const ADDRESS_CANCEL = "/sdapi/v1/interrupt"
const ADDRESS_IMAGE_INFO = "/sdapi/v1/png-info"

# CONFIGS
const CONTROLNET_CONFIG = "Control Net"
const CONTROLNET_MAX_MODELS_NUM_1 = "control_net_max_models_num"
const CONTROLNET_MAX_MODELS_NUM_2 = "control_net_unit_count"
const CONTROLNET_MAX_MODELS_NUM_3 = "control_max_units"
const RECOMMENDED_MODELS_NUM = 10
const MSG_NO_CONTROLNET = "MESSAGE_NO_CONTROLNET"

# API PATHS KEYS
const PATH_KEY_LORA_DIR = "lora_dir"
const PATH_KEY_LYCO_DIR = "lyco_dir"
const PATH_KEY_EMBEDDINGS_DIR = "embeddings_dir"
const PATH_KEY_CHECKPOINTS_DIR = "ckpt_dir"
const PATH_KEY_CONTROL_DIR = "control_dir"

# PROGRESS KEYS
const PROGRESS_KEY = "progress"
const PROGRESS_STATE_KEY = "state"
const PROGRESS_STATE_JOB_COUNT = "job_count"


# DEFAULT_PATHS
var models_dir: String = "models"
var lora_dir: String = "models/Lora"
var lyco_dir: String = "models/LyCORIS"
var embeddings_dir: String = "models/embeddings"
var ckpt_dir: String = "models/Stable-diffusion"
var control_dir: String = "models/ControlNet"
var donwload_control_dir: String = "models/ControlNet/"

# API ROUTE SHORTCUTS
var context = MAIN_API_CONTEXT
var service = TEXT2IMG_SERVICE

# Removed keys: 
# styles, subseed, subseed_strength, seed_resize_from_h, seed_resize_from_w, 
# do_not_save_samples, do_not_save_grid, sampler_index, alwayson_scripts, script_name
# script_args, hr_resize_x, hr_resize_y
# (removing these gives me consistent results with web ui)
# eta: 0, s_churn: 0, s_tmax: 0, s_tmin: 0, s_noise: 1 
var txt2img_dict: Dictionary = {
	"enable_hr": false,
	"denoising_strength": 0.7, # used hi hr, advanced mode only
	#"firstphase_width": 0,
	#"firstphase_height": 0,
	#"hr_scale": 2,
	#"hr_upscaler": "",
	#"hr_second_pass_steps": 0,
	"prompt": "", 
	"seed": -1,
	"sampler_name": "Euler a",
	"batch_size": 1,
	"n_iter": 1,
	"steps": 20,
	"cfg_scale": 7,
	"width": 512,
	"height": 512,
	"restore_faces": false,
	"tiling": false,
	"negative_prompt": "", #"EasyNegative",
	"override_settings": {},
	"override_settings_restore_afterwards": true, # this one is not configurable
	"send_images": true, # this one is not configurable
	"save_images": false, # this one is not configurable
	"alwayson_scripts": {},
}


func _ready():
	extra_samplers = []
	extra_upscalers = ["Latent"]
	default_sampler = "Euler"
	default_upscaler = "Latent"
	DIR_LORA = lora_dir
	DIR_LYCORIS = lyco_dir
	DIR_TI = embeddings_dir
	DIR_DIFFUSION_MODELS = ckpt_dir
	DIR_CONTROLNET_MODELS = control_dir
	ADDRESS_GET_CONTROLNET_SETTINGS = "/controlnet/settings"
	ADDRESS_GET_SERVER_CONFIG = "/sdapi/v1/options"
	ADDRESS_SET_SERVER_CONFIG = "/sdapi/v1/options"
	ADDRESS_SHUTDOWN_SERVER = "/sdapi/v1/shutdown"
	PCData.install_python_library("psutil", false)
	clear()


func load_modules():
	controlnet = add_module(
			DiffusionServer.FEATURE_CONTROLNET, 
			"res://server/available_apis/auto_web_ui_control_net.gd"
	)
	image_info = add_module(
			DiffusionServer.FEATURE_IMAGE_INFO, 
			"res://server/available_apis/auto_web_ui_image_info.gd"
	)
	img_to_img = add_module(
			DiffusionServer.FEATURE_IMG_TO_IMG, 
			"res://server/available_apis/auto_web_ui_img_to_img.gd"
	)
	inpaint_outpaint = add_module(
			DiffusionServer.FEATURE_INPAINT_OUTPAINT, 
			"res://server/available_apis/auto_web_ui_inpaint_outpaint.gd"
	)


func load_urls():
	server_urls = [
		"http://127.0.0.1:7860",
		"http://127.0.0.1:7861",
		"http://127.0.0.1:7862",
	]


func generate(response_object: Object, response_method: String, custom_gen_data: Dictionary = {}):
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = server_address.url + context + service
	# ADD TO TEMPLATE
	api_request.connect_on_request_failed(DiffusionServer, "_on_generation_failed")
	if custom_gen_data.empty():
		api_request.api_post(url, request_data)
	else:
		api_request.api_post(url, custom_gen_data)
	
	return api_request


func get_images_from_result(result, debug: bool, img_name: String) -> Array: 
	# This function should return an array of ImageData
	# Debug will include the controlnet images sent
	
	var images_key_base64 = result.get('images')
	var resul_base64 = []
	if images_key_base64 is String:
		resul_base64.append(images_key_base64)
	elif images_key_base64 is Array:
		for image in images_key_base64:
			resul_base64.append(image)
	
	if debug:
		# Controlnet images haven't been removed
		return _base64_to_image_data(resul_base64, img_name)
	if controlnet != null:
		resul_base64 = controlnet.remove_controlnet_images_from_result(result, resul_base64)
	return _base64_to_image_data(resul_base64, img_name)


func get_seed_from_result(result) -> int:
	var resul_info = result.get('info')
	var last_seed = -1
	if resul_info is String:
		resul_info = JSON.parse(resul_info).result
	if resul_info is Dictionary:
		last_seed = int(resul_info.get('seed', -1))
	if last_seed == -1:
		l.g("Couldn't recover seed of last generated image")
	
	return last_seed




func request_progress(response_object: Object, response_method: String):
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = server_address.url + ADDRESS_GET_PROGRESS
	api_request.api_get(url)


func get_progress_from_result(result):
	if not result is Dictionary:
		return 0.0
	
	var progress = result.get(PROGRESS_KEY, 0.0)
	if not _progress_has_job_count(result):
		return -1.0
	else:
		return progress


func _progress_has_job_count(results: Dictionary, only_zero_is_false: bool = true):
	var state = results.get(PROGRESS_STATE_KEY, {})
	var job_count = null
	if state is Dictionary:
		job_count = state.get(PROGRESS_STATE_JOB_COUNT, null)
	
	if job_count == null:
		l.g("Failure to retrieve job count on pi_auto_web_ui.gd. Data: " + 
				str(results))
		job_count = 0
	
	if only_zero_is_false:
		return int(job_count) != 0
	else:
		return job_count > 0


func reset_data():
	context = MAIN_API_CONTEXT
	service = TEXT2IMG_SERVICE
	request_data = txt2img_dict.duplicate(true)


func add_to_prompt(positive_prompt: String, negative_prompt: String): 
	# [positive_prompt, negative_prompt]
	# also accepts a config dictionary, will use this if the arguments are emtpy
	
	var old_value: String = ''
	# Adding the positive prompt, checking args first, then options if empty
	if not positive_prompt.empty():
		old_value = request_data[Consts.I_PROMPT].strip_edges()
		if old_value.empty():
			request_data[Consts.I_PROMPT] += positive_prompt.strip_edges()
		else:
			request_data[Consts.I_PROMPT] += ", " + positive_prompt.strip_edges()
	
	# Adding the negative prompt, checking args first, then options if empty
	if not negative_prompt.empty():
		old_value = request_data[Consts.I_NEGATIVE_PROMPT].strip_edges()
		if old_value.empty():
			request_data[Consts.I_NEGATIVE_PROMPT] += negative_prompt.strip_edges()
		else:
			request_data[Consts.I_NEGATIVE_PROMPT] += ", " + negative_prompt.strip_edges()


func replace_prompt(positive_prompt, negative_prompt):
	# [positive_prompt, negative_prompt]
	if positive_prompt is String:
		request_data[Consts.I_PROMPT] = positive_prompt.strip_edges()
	if negative_prompt is String:
		request_data[Consts.I_NEGATIVE_PROMPT] = negative_prompt.strip_edges()


func apply_parameters(parameters: Dictionary): 
	# the parameters lies in the cue's dictionary (aka options)
	var override_settings = parameters.get(Consts.I_OVERRIDE_SETTINGS)
	if override_settings is Dictionary and not override_settings.empty():
		_merge_dict(request_data["override_settings"], override_settings)
# warning-ignore:return_value_discarded
		parameters.erase(Consts.I_OVERRIDE_SETTINGS)
	
	_merge_dict(request_data, parameters)


func replace_parameters(parameters: Dictionary): 
	# the config lies in the cue's dictionary (aka options)
	request_data = parameters


func _merge_dict(base_dict: Dictionary, overwrite_dict: Dictionary):
	base_dict.merge(overwrite_dict, true)


func get_request_data_no_images(custom_data: Dictionary = {}) -> Dictionary:
	var data_copy
	if custom_data.empty():
		data_copy = request_data.duplicate(true)
	else:
		data_copy = custom_data.duplicate(true)
	
	debug_scrub_dict_key_string(data_copy, "init_images", false)
	debug_scrub_dict_key_string(data_copy, "mask", false)
	return controlnet.remove_images_from_request_data(data_copy)


func get_request_data_no_images_no_prompts(custom_data: Dictionary = {}) -> Dictionary: 
	var data_copy = get_request_data_no_images(custom_data)
	
	debug_scrub_dict_key_string(data_copy, "prompt", true)
	debug_scrub_dict_key_string(data_copy, "negative_prompt", true)
	return data_copy


func get_current_diffusion_model(response_object: Object, response_method: String):
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = server_address.url + ADDRESS_GET_SERVER_CONFIG
	api_request.api_get(url)


func get_diffusion_model_from_result(server_config_result: Dictionary):
	var full_name = server_config_result.get("sd_model_checkpoint", '')
	if full_name is String:
		full_name = full_name.substr(0, full_name.rfind(' '))
		return full_name.get_basename()
	else:
		return ''


func set_server_diffusion_model(model_file_name: String, response_object: Object, 
success_method: String, failure_method: String):
	var api_request = APIRequest.new(response_object, success_method, self)
	api_request.connect_on_request_failed(response_object, failure_method)
	var url = server_address.url + self.ADDRESS_SET_SERVER_CONFIG
	api_request.api_post(url, {"sd_model_checkpoint": model_file_name.get_file()})


func cancel_diffusion():
	var api_request = APIRequest.new(DiffusionServer, "_on_diffusion_canceled", self)
	var url = server_address.url + self.ADDRESS_CANCEL
	api_request.api_post(url, {})


func probe_server(current_server_address: ServerAddress):
	# checks if server is there, signals server_probed(success: bool)
	server_address = current_server_address
	var api_request = APIRequest.new(self, "_on_probe_success", self)
	api_request.connect_on_request_failed(self, "_on_prove_failed")
	api_request.push_server_down_error = false
	api_request.print_network_error = false
	var url = server_address.url + ADDRESS_GET_SERVER_CONFIG
	if Consts.pc_data.is_windows():
		api_request.api_node.timeout = 1.0
	api_request.api_get(url)


func _on_probe_success(result):
	if result is Dictionary:
		refresh_paths(result)
	else:
		l.g("Can't refresh paths on AutoWebUi class API, returned configuration is: " + str(result))
	emit_signal("server_probed", true)


func _on_prove_failed(_result):
	emit_signal("server_probed", false)


func refresh_paths(api_result: Dictionary = {}):
	var aux
	var install_path = get_installation_dir()
	var confirmation_path = install_path.plus_file(models_dir)
	
	DIR_LORA = install_path.plus_file(lora_dir)
	aux = api_result.get(PATH_KEY_LORA_DIR, '')
	if aux is String and not aux.empty():
		DIR_LORA = _interpret_api_path(aux, lora_dir)
		PCData.conditional_make_dir_recursive(DIR_LORA, confirmation_path)
		
	l.g("LoRA models directory set as: " + DIR_LORA, l.DEBUG)
	
	DIR_LYCORIS = install_path.plus_file(lyco_dir)
	aux = api_result.get(PATH_KEY_LYCO_DIR, '')
	if aux is String and not aux.empty():
		DIR_LYCORIS = _interpret_api_path(aux, lyco_dir)
		PCData.conditional_make_dir_recursive(DIR_LYCORIS, confirmation_path)
		
	l.g("LyCORIS models directory set as: " + DIR_LYCORIS, l.DEBUG)
	
	DIR_TI = install_path.plus_file(embeddings_dir)
	aux = api_result.get(PATH_KEY_EMBEDDINGS_DIR, '')
	if aux is String and not aux.empty():
		DIR_TI = _interpret_api_path(aux, embeddings_dir)
		PCData.conditional_make_dir_recursive(DIR_TI, confirmation_path)
		
	l.g("Textual inversion models directory set as: " + DIR_TI, l.DEBUG)
	
	DIR_DIFFUSION_MODELS = install_path.plus_file(ckpt_dir)
	aux = api_result.get(PATH_KEY_CHECKPOINTS_DIR, '')
	if aux is String and not aux.empty():
		DIR_DIFFUSION_MODELS = _interpret_api_path(aux, ckpt_dir)
		PCData.conditional_make_dir_recursive(DIR_DIFFUSION_MODELS, confirmation_path)
		
	l.g("Diffusion models directory set as: " + DIR_DIFFUSION_MODELS, l.DEBUG)
	
	DIR_CONTROLNET_MODELS = install_path.plus_file(control_dir)
	aux = api_result.get(PATH_KEY_CONTROL_DIR, '')
	if aux is String and not aux.empty():
		var dir: Directory = Directory.new()
		var multiple_possible_dirs: bool = false
		var default_dir = install_path.plus_file(control_dir)
		DIR_CONTROLNET_MODELS = _interpret_api_path(aux, control_dir)
		
		if dir.dir_exists(DIR_CONTROLNET_MODELS.plus_file("controlnet")):
			DIR_CONTROLNET_MODELS = DIR_CONTROLNET_MODELS.plus_file("controlnet")
		
		if default_dir != DIR_CONTROLNET_MODELS and dir.dir_exists(default_dir):
			multiple_possible_dirs = true
		
		if  multiple_possible_dirs:
			# check which one has more clusters, current folder or default
			# Get file num from both sides and pick who has most
			var custom_dir_models = Cue.new(Consts.ROLE_FILE_PICKER, "get_file_paths").args([
				DIR_CONTROLNET_MODELS, ".pth", ".safetensors"
			]).execute()
			var default_dir_models = Cue.new(Consts.ROLE_FILE_PICKER, "get_file_paths").args([
				default_dir, ".pth", ".safetensors"
			]).execute()
			# Printing found models amount for debug purposes
			l.g("Control Net models in " + DIR_CONTROLNET_MODELS + ": " + 
					str(custom_dir_models.size()), l.DEBUG)
			l.g("Control Net models in " + default_dir + ": " + 
					str(default_dir_models.size()), l.DEBUG)
			
			# Selecting the winning model
			if default_dir_models.size() >= custom_dir_models.size():
				DIR_CONTROLNET_MODELS = install_path.plus_file(control_dir)
			else:
				pass # DIR_CONTROLNET_MODELS already has the custom path
			
		PCData.conditional_make_dir_recursive(DIR_CONTROLNET_MODELS, confirmation_path)
		
	l.g("Control Net models directory set as: " + DIR_CONTROLNET_MODELS, l.DEBUG)
	
	emit_signal("paths_refreshed")


func _interpret_api_path(api_path: String, default_path: String) -> String:
	# If path exists, return it as it is, if not, add the repo folder and test again
	# If that doesn't work either, go for the default
	var dir: Directory = Directory.new()
	var install_path: String = get_installation_dir()
	# PENDING see how install_path appears on windows and change/adjust the '/' as needed
	if dir.dir_exists(api_path):
		return api_path
	elif dir.dir_exists(install_path.plus_file(api_path)):
		return install_path.plus_file(api_path)
	else:
		return install_path.plus_file(default_path)


func adjust_server():
	# checks configuration and configures server if needed, signals server_verified(success: bool)
	
	# This is just for debug purposes
	config_report.add(CONTROLNET_CONFIG)
	
	# We are going the check cn (controlnet) configuration
	# "auto-web-ui check controlnet num" is the id of this sequence, it will be used
	# to, on next startup, go directly to the valid API endpoint
	var check_cn = APISequence.new(self, "auto-web-ui check controlnet num", APISequence.NO_STOP)
	var url = server_address.url
	
	# if API endpoint ADDRESS_GET_CONTROLNET_SETTINGS succeds, it will send the result
	# to _config_check_controlnet_1
	check_cn.add_get(url + ADDRESS_GET_CONTROLNET_SETTINGS, "_config_check_controlnet_1")
	# if the previous API endpoint fails, it will try instead ADDRESS_GET_SERVER_CONFIG, and if
	# ut succeds, it will send the result to _config_check_controlnet_2
	check_cn.add_get(url + ADDRESS_GET_SERVER_CONFIG, "_config_check_controlnet_2")
	
	# This will start the sequence of API calls, it will stop on first success and on the 
	# next startup will call directly the valid API endpoint, or try again from the beginning 
	# if for whatever reason it fails
	check_cn.run_success(true)


func _config_check_controlnet_1(result, api_sequence: APISequence):
	var num: int = -1
	var valid_key = ''
	if not result is Dictionary:
		l.g("Couldn't check Control Net api configuration, result is not a dictionary.")
		return
	
	valid_key = CONTROLNET_MAX_MODELS_NUM_1
	num = int(result.get(CONTROLNET_MAX_MODELS_NUM_1, -1))
	if num == -1:
		valid_key = CONTROLNET_MAX_MODELS_NUM_2
		num = int(result.get(CONTROLNET_MAX_MODELS_NUM_2, -1))
	
	if num == -1:
		l.g("Couldn't check Control Net api configuration, result: " + str(result), l.DEBUG)
		return
	
	# This is just for debug purposes
	config_report.success_get(CONTROLNET_CONFIG, num, RECOMMENDED_MODELS_NUM)
	
	# This line s just in case, it will stop the sequence since we succeded
	api_sequence.force_stop()
	
	if num != RECOMMENDED_MODELS_NUM:
		l.g("Reconfiguring Control Net", l.DEBUG)
		_configure_server(valid_key, RECOMMENDED_MODELS_NUM)
	else:
		l.g("Server started with " + str(num) + " available controlnets.", l.DEBUG)
		emit_signal("server_adjusted", true)
	


func _config_check_controlnet_2(result, api_sequence: APISequence):
	var num: int = -1
	var valid_key = ''
	if not result is Dictionary:
		l.g("Couldn't check Control Net api configuration, result is not a dictionary.")
		emit_signal("server_adjusted", false)
		return
	
	valid_key = CONTROLNET_MAX_MODELS_NUM_3
	num = int(result.get(CONTROLNET_MAX_MODELS_NUM_3, -1))
	
	if num == -1:
		l.g("Couldn't find Control Net configuration in general configuration.", l.DEBUG)
		emit_signal("server_adjusted", false)
		return
	
	# This is just for debug purposes
	config_report.success_get(CONTROLNET_CONFIG, num, RECOMMENDED_MODELS_NUM)
	
	# This line s just in case, it will stop the sequence since we succeded
	api_sequence.force_stop()
	
	if num != RECOMMENDED_MODELS_NUM:
		l.g("Reconfiguring Control Net", l.DEBUG)
		_configure_server(valid_key, RECOMMENDED_MODELS_NUM)
	else:
		l.g("Server started with " + str(num) + " available controlnets.", l.DEBUG)
		emit_signal("server_adjusted", true)


func _configure_server(configure_key: String, optimal_value):
	var api_request = APIRequest.new(self, "_on_cn_config_success", self)
	api_request.connect_on_request_failed(self, "_on_cn_config_failed")
	var url = server_address.url + ADDRESS_SET_SERVER_CONFIG
	var data = {
			configure_key: optimal_value
		}
	api_request.api_post(url, data)


func _on_cn_config_success(_result):
	config_report.success_set(CONTROLNET_CONFIG)
	DiffusionServer.server.restart_server() # This will start probe & adjust process again


func _on_cn_config_failed(result: int):
	emit_signal("server_adjusted", false)
	if result >= 400 and result <= 505:
		l.g("The server responds to the configuration request, but the configuration failed." +
				" Proceeding with current configuration. Error code: " + str(result), l.WARNING)


func stop_server():
	l.g("Server shutdown requested.", l.INFO)
	var api_request = APIRequest.new(self, "_on_server_shutdown_success", self)
	api_request.connect_on_request_failed(self, "_on_server_shutdown_failure")
	var url = server_address.url + ADDRESS_SHUTDOWN_SERVER
	api_request.api_post(url, {})
	return self


func _on_server_shutdown_success(_result):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
			Consts.HELP_DESC_SERVER_SHUTDOWN]).execute()
	DiffusionServer.set_state(Consts.SERVER_STATE_SHUTDOWN)
	emit_signal("server_stopped")


func _on_server_shutdown_failure(result: int):
	var tree = get_tree()
	if result == 500:
		if tree != null:
			yield(get_tree().create_timer(0.5), "timeout")
		emit_signal("server_stopped")
		return
	
	
	var repo = DiffusionServer.running_repo
	if not repo is LocalRepo:
		# repo is not a LocalRepo, but null or something
		emit_signal("server_stopped")
		return
		
	l.g("Shutdown signal failed, attempting to terminate server", l.DEBUG)
	PCData.install_python_library("psutil", true)
	if Python.kill():
		if tree != null:
			yield(get_tree().create_timer(1.5), "timeout")
	emit_signal("server_stopped")


func refresh_data(what: String):
	var is_all = what == REFRESH_ALL
	var result = {}
	var success
	
	if is_all or what == REFRESH_CONTROLNET_MODELS:
		var api_request = APIRequest.new(self, "_on_contronet_models_refreshed", self)
		api_request.connect_on_request_failed(self, "_on_contronet_models_failed_refresh")
		var url = server_address.url + ADDRESS_GET_CONTROLNET_MODEL_LIST
		success = yield(api_request.api_get(url), "api_request_finished")
		
		result[REFRESH_CONTROLNET_MODELS] = success
	
	if is_all or what == REFRESH_SAMPLERS:
		var api_request = APIRequest.new(self, "_on_samplers_refreshed", self)
		var url = server_address.url + ADDRESS_GET_SAMPLERS
		success = yield(api_request.api_get(url), "api_request_finished")
		
		result[REFRESH_SAMPLERS] = success
	
	if is_all or what == REFRESH_UPSCALERS:
		var api_request = APIRequest.new(self, "_on_upscalers_refreshed", self)
		var url = server_address.url + ADDRESS_GET_UPSCALERS
		success = yield(api_request.api_get(url), "api_request_finished")
		
		result[REFRESH_UPSCALERS] = success
	
	if is_all or what == REFRESH_MODELS:
		var api_request = APIRequest.new(self, "_on_diffusion_models_refreshed", self)
		var url = server_address.url + ADDRESS_REFRESH_DIFFUSION_MODELS
		success = yield(api_request.api_post(url, {}), "api_request_finished")
		
		result[REFRESH_MODELS] = success
	
	emit_signal("data_refreshed", result)


func _on_contronet_models_refreshed(result):
	DiffusionServer.controlnet_models = result["model_list"]
	if not DiffusionServer.controlnet_models is Array:
		l.g("Couldn't retrieve the controlnet models")
		DiffusionServer.controlnet_models = null
		return
	
	if DiffusionServer.controlnet_models.empty():
		l.g("No controlnet models found", l.INFO)


func _on_contronet_models_failed_refresh(_result):
	DiffusionServer.features.uncheck(DiffusionServer.FEATURE_CONTROLNET)
	var repo = Cue.new(Consts.ROLE_SERVER_MANAGER, "get_local_repository").execute()
	if repo is AutoWebUI_Repo:
		repo.prepare_files()
		Tutorials.cancel_all()
		Cue.new(Consts.ROLE_DIALOGS, "request_confirmation").args([
			MSG_NO_CONTROLNET,
			self,
			"_on_confirm_no_controlnet"
		]).execute()
	else:
		l.g("Couldn't configure/enable controlnet on AutoWebUI class API, repo was: " + str(repo))
		Cue.new(Consts.ROLE_SERVER_MANAGER, "hide_installation_window").execute()


func _on_confirm_no_controlnet():
	Cue.new(Consts.ROLE_SERVER_MANAGER, "hide_installation_window").execute()


func _on_samplers_refreshed(result):
	var success = result is Array and not result.empty()
	if not success:
		l.g("Couldn't retrieve the samplers")
		DiffusionServer.samplers = null
	
	var sampler_name: String = ''
	var samplers = []
	for dict in result:
		sampler_name = dict.get("name", '')
		if not sampler_name.empty():
			samplers.append(sampler_name)
	
	samplers.append_array(extra_samplers)
	DiffusionServer.samplers = samplers


func _on_upscalers_refreshed(result):
	var success = result is Array and not result.empty()
	if not success:
		l.g("Couldn't retrieve the upscalers")
		DiffusionServer.upscalers = null
	
	var upscaler_name: String = ''
	var upscalers = []
	for dict in result:
		upscaler_name = dict.get("name", '')
		if upscaler_name.to_lower().strip_edges() == 'none':
			continue
		if not upscaler_name.empty():
			upscalers.append(upscaler_name)
	
	upscalers.append_array(extra_upscalers)
	DiffusionServer.upscalers = upscalers


func _on_diffusion_models_refreshed(_result):
	pass # nothing to do here at the current way the api works















func apply_safe_mode(_cue: Cue = null):
	# Currently not in use
	# Just here in case a formal or an all-ages-friendly presentation occurs
	# This eliminates things from the prompt and add stuff to the negative prompt to make it SFW
	var _prompt: String = request_data[Consts.I_PROMPT]
	var neg_prompt: String = request_data[Consts.I_NEGATIVE_PROMPT]
	var add_to_negative = ['porn', 'EasyNegative', 'nsfw']
	if not neg_prompt.empty():
		neg_prompt += ", "
	for word in add_to_negative:
		neg_prompt += word + ", "
	neg_prompt = neg_prompt.substr(0, neg_prompt.length() - 2)
	request_data[Consts.I_NEGATIVE_PROMPT] = neg_prompt
