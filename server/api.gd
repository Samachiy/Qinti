extends HTTPRequest

class_name DiffusionAPI

const REFRESH_ALL = "all"
const REFRESH_MODELS = "diffusion models"
const REFRESH_CONTROLNET_MODELS = "controlnet models"
const REFRESH_CONTROLNET_MODELS_LOCAL = "controlnet models local"
const REFRESH_SAMPLERS = "samplers"
const REFRESH_UPSCALERS = "upscalers"

const MASK_MODE_INPAINT = "inpaint"
const MASK_MODE_OUTPAINT = "outpaint"

# Technically this should be consts, but since they need to be overriden, we set them as vars
var SUBDIR_LORA = ""
var SUBDIR_LYCORIS = ""
var SUBDIR_TI = ""
var SUBDIR_DIFFUSION_MODELS = ""
var SUBDIR_CONTROLNET_MODELS = ""
var DOWNLOAD_SUBDIR_LORA = ""
var DOWNLOAD_SUBDIR_LYCORIS = ""
var DOWNLOAD_SUBDIR_TI = ""
var DOWNLOAD_SUBDIR_DIFFUSION_MODELS = ""
var DOWNLOAD_SUBDIR_CONTROLNET_MODELS = ""
var ADDRESS_GET_CONTROLNET_SETTINGS = ""
var ADDRESS_GET_SERVER_CONFIG = ""
var ADDRESS_SET_SERVER_CONFIG = ""
var ADDRESS_SHUTDOWN_SERVER = ""

var extra_samplers = []
var extra_upscalers = []
var default_sampler = ''
var default_upscaler = ''

var config_report: ConfigReport = ConfigReport.new()
var server_address: ServerAddress = null

var request_data: Dictionary = {} 

var img2img_to_bake: Array = [] # [ data_dict1, data_dict2, ... ]
var controlnet_to_bake: Dictionary = {
	Consts.CN_TYPE_SHUFFLE: [], # [ data_dict1, data_dict2, ... ] 
	Consts.CN_TYPE_DEPTH: [],
	Consts.CN_TYPE_CANNY: [],
	Consts.CN_TYPE_LINEART: [],
	Consts.CN_TYPE_MLSD: [],
	Consts.CN_TYPE_NORMAL: [],
	Consts.CN_TYPE_OPENPOSE: [],
	Consts.CN_TYPE_SCRIBBLE: [],
	Consts.CN_TYPE_SEG: [],
	Consts.CN_TYPE_SOFTEDGE: [],
}
var mask_to_bake: Array = [] # [ mask, base_image, mode ] base_image is what will appear
#							in the unmasked area, mode is MASK_MODE_INPAINT or MASK_MODE_OUTPAINT
var regions_to_bake: Array = [] # [ [rect2_1, data_dict1], [rect2_2, data_dict2], ... ]

var controlnet_bgs: Dictionary = {
	Consts.CN_TYPE_CANNY: Color.black,
	Consts.CN_TYPE_LINEART: Color.black,
	Consts.CN_TYPE_MLSD: Color.black,
	Consts.CN_TYPE_SOFTEDGE: Color.black,
	Consts.CN_TYPE_OPENPOSE: Color.black,
	Consts.CN_TYPE_DEPTH: Color.black,
	Consts.CN_TYPE_NORMAL: Color.mediumpurple,
}

# Modules
var controlnet: DiffusionAPIModule = null
var image_info: DiffusionAPIModule = null
var img_to_img: DiffusionAPIModule = null
var inpaint_outpaint: DiffusionAPIModule = null
var region_prompt: DiffusionAPIModule = null


# warning-ignore:unused_signal
signal server_probed(success)
# warning-ignore:unused_signal
signal server_adjusted(success)
# warning-ignore:unused_signal
signal server_stopped
# warning-ignore:unused_signal
signal data_refreshed(what_dict) # { what_1: success_bool_1, what_2: success_bool_2, ... }
# warning-ignore:unused_signal
signal paths_refreshed 



# GENERIC FUNCTIONS


func add_module(module_name: String, script_path: String):
	var script = load(script_path)
	var node = script.new()
	add_child(node)
	node.name = module_name
	node.api = self
	return node


# COMMON UTILITIES


func _base64_to_image_data(images: Array, image_name: String) -> Array:
	var resul = []
	for base64 in images:
		if base64 is String:
			resul.append(ImageData.new(image_name).load_base64(base64))
	
	return resul


func blend_images(images: Array, width: int, height: int, bg_color = null, default = null):
	var new_image = Image.new()
	var is_null = true
	new_image.create(width, height, false, Image.FORMAT_RGBA8)
	if bg_color is Color:
		new_image.fill(bg_color)
	
	for image in images:
		if image is ImageData:
			ImageProcessor.blend_images(new_image, image.image)
			is_null = false
		elif image is Image:
			ImageProcessor.blend_images(new_image, image)
			is_null = false
	
	if is_null:
		return default
	else:
		return new_image


func blend_images_at_dictionaries_key(key: String, dictionaries: Array, width: int, 
height: int, dict_value_is_array: bool, bg_color = null, encode_base64: bool = true):
	var aux = []
	if dict_value_is_array:
		for dict in dictionaries:
			aux.append_array(dict.get(key, [null]))
	else:
		for dict in dictionaries:
			aux.append(dict.get(key, null))
	
	if encode_base64:
		return ImageProcessor.image_to_base64(blend_images(aux, width, height, bg_color))
	else:
		return blend_images(aux, width, height, bg_color)


func overlap_values_at_dictionaries_key(key: String, dictionaries: Array, default_value):
	var resul = default_value
	var new_value
	for dict in dictionaries:
		new_value = dict.get(key, null)
		if new_value != null:
			resul = new_value
	
	return resul


func average_nums_at_dictionaries_key(key: String, dictionaries: Array, 
default_value, replace_null_with_default: bool = false): # parent
	var values = []
	var amount: int = 0
	var aux
	var is_num: bool
	for dict in dictionaries:
		aux = dict.get(key, null)
		is_num = aux is int or aux is float
		if is_num:
			values.append(float(aux))
			amount += 1
		elif replace_null_with_default:
			values.append(default_value)
			amount += 1
	
	aux = 0
	for num in values:
		aux += num
	
	if amount == 0:
		return default_value
	else:
		return aux / amount


func get_image_to_image_data(width: int, height: int) -> Dictionary:
	var result: Dictionary = {
		"init_images": null, # This will return a Image object since it may be user by the mask
		"denoising_strength": 0.7,
		"image_cfg_scale": 0,
	}
	var base_image: Image
	# RESUME this whole block from here and var resul: Dictionary = img2img_dict.duplicate()
	for key in result.keys():
		match key:
			"init_images":
				base_image = blend_images_at_dictionaries_key(
						key, img2img_to_bake, width, height, false, null, false
				)
#				base_image.save_png("user://img2img_base")
				# warning-ignore:return_value_discarded
				result.erase("init_images")
				# We dont encode it as base64 because inpaint_outpaint module will do that for us
				result[key] = base_image
			"image_cfg_scale", "cfg_scale", "denoising_strength":
				result[key] = average_nums_at_dictionaries_key(
						key, img2img_to_bake, result[key]
						)
			_:
				result[key] = overlap_values_at_dictionaries_key(
						key, img2img_to_bake, result[key]
						)
	return result


func get_controlnet_data(width: int, height: int) -> Dictionary:
	var data: Dictionary = {}
	var control_net_array
	for controlnet_type in controlnet_to_bake.keys():
		control_net_array = controlnet_to_bake.get(controlnet_type)
		if control_net_array is Array and not control_net_array.empty():
			data[controlnet_type] = _consolidate_one_controlnet(
					control_net_array, 
					width, 
					height, 
					controlnet_type
			)
	
	return data


func _consolidate_one_controlnet(dictionaries: Array, width: int, height: int, type: String):
	var result: Dictionary = {
		"input_image": "", # base64 image
		"model": "", # Controlnet model to use
		"weight": 1,
		"guidance_start": 0, # advanced mode only
		"guidance_end": 1, # advanced mode only
		"control_mode": 2, # 0 = balanced, 1 = prompt more important, 2 = controlnet more important
	}
	for key in result.keys():
		match key:
			"input_image":
				result[key] = blend_images_at_dictionaries_key(
						key, dictionaries, width, height, false, controlnet_bgs.get(type, null)
						)
			"weight", "guidance_start", "guidance_end":
				result[key] = average_nums_at_dictionaries_key(
						key, dictionaries, result[key]
						)
			_:
				result[key] = overlap_values_at_dictionaries_key(
						key, dictionaries, result[key]
						)
	
	return result


# RESET API INFO FOR NEW REQUEST


func clear_queues():
	img2img_to_bake = []
	mask_to_bake = []
	regions_to_bake = []
	for array in controlnet_to_bake.values():
		if array is Array:
			array.resize(0)


func clear(_cue : Cue = null): 
	# Clears the request_data back to it's original state
	l.g("The function 'clear' has not been overriden yet on Api: " + 
	name)


# GENERATE


func generate(_response_object: Object, _response_method: String, 
_custom_gen_data: Dictionary = {}) -> APIRequest:
	# custom_gen_data is meant for the retry button, so it is essentially the previous request_data
	l.g("The function 'generate' has not been overriden yet on Api: " + 
	name)
	return null


func get_images_from_result(_result, _debug: bool, _img_name: String) -> Array:
	# This function should return an array of ImageData
	# Debug will include the controlnet images sent or even print any extra data
	l.g("The function 'get_images_from_result' has not been overriden yet on Api: " + 
	name)
	return []


func get_seed_from_result(_result) -> int:
	# This function should return the seed as an int
	l.g("The function 'get_seed_from_result' has not been overriden yet on Api: " + 
	name)
	return -1


func request_progress(_response_object: Object, _response_method: String):
	l.g("The function 'request_progress' has not been overriden yet on Api: " + 
	name)
	return null


func get_progress_from_result(_result) -> float:
	# Returns progress as a float between 0.0 and 1.0, representing the percentage of progress
	# Returns 0.0 if there's no way to see the progress
	# Returns -1.0 if there's no job
	l.g("The function 'get_progress_from_result' has not been overriden yet on Api: " + 
	name)
	return 0.0


# TXT2IMG


func add_to_prompt(_cue: Cue): 
	# [positive_prompt, negative_prompt]
	# also accepts a config dictionary, will use this if the arguments are emtpy
	# the config dictionary will can be read with:
	#	var p_prompt = cue.get_option(Consts.I_PROMPT, '') 
	#	var n_prompt = cue.get_option(Consts.I_NEGATIVE_PROMPT, '')
	l.g("The function 'add_to_prompt' has not been overriden yet on Api: " + 
	name)


func replace_prompt(_cue: Cue):
	# [positive_prompt, negative_prompt]
	# also accepts a config dictionary, will use this if the arguments are emtpy
	# the config dictionary will can be read with:
	#	var p_prompt = cue.get_option(Consts.I_PROMPT, '') 
	#	var n_prompt = cue.get_option(Consts.I_NEGATIVE_PROMPT, '')
	l.g("The function 'replace_prompt' has not been overriden yet on Api: " + 
	name)


func apply_parameters(_cue: Cue): 
	# the parameters lies in the cue's dictionary (aka options), those must be applied/merged to
	# request_data, they will come using the names specified in Consts.gd, so running it with
	# translate_dictionary() may be needed
	l.g("The function 'apply_parameters' has not been overriden yet on Api: " + 
	name)


func replace_parameters(_cue: Cue): 
	# the parameters lies in the cue's dictionary (aka options), request_data values must
	# be entirely replaced with those here, values that don't exist in the dictionary should 
	# not be in request_data either. Configs will come using the names specified in Consts.gd, 
	# so running it with translate_dictionary() may be needed
	l.g("The function 'replace_parameters' has not been overriden yet on Api: " + 
	name)


# IMG2IMG


func queue_img2img_to_bake(dict: Dictionary): 
	if dict == null:
		return
	
	img2img_to_bake.append(dict.duplicate(true))


func bake_pending_img2img(_cue: Cue = null):
	if img_to_img is DiffusionAPIModule:
		img_to_img.bake_pending_img2img()
	else:
		l.g("Tried to use 'bake_pending_img2img' but api has no img2img module")


# INPAINT, OUTPAINT


func queue_mask_to_bake(mask: Image, base_image: Image, mode: String): 
	# Since we are going to blend the image manually rather than on ImageProcessor
	# We fix the formating right now (Image processor is supposed to fix formating)
	if mask == null:
		l.g("Can't queue mask, mask is not an Image.")
		return
	
	if base_image == null:
		l.g("Can't queue mask, unmasked background is not an Image.")
		return
	
	mask.convert(Image.FORMAT_RGBA8)
	base_image.convert(Image.FORMAT_RGBA8)
	mask_to_bake = [mask, base_image, mode]


func bake_pending_mask(_cue: Cue = null):
	if inpaint_outpaint is DiffusionAPIModule:
		inpaint_outpaint.bake_pending_mask()
	else:
		l.g("Tried to use 'bake_pending_img2img' but api has no img2img module")


# IMAGE INFORMATION


func request_image_info(response_object: Object, response_method: String, image_base64: String):
	if image_info is DiffusionAPIModule:
		image_info.request_image_info(response_object, response_method, image_base64)
	else:
		l.g("Tried to use 'request_image_info' but api has no image info module")


func get_image_info_from_result(result) -> Dictionary:
	if image_info is DiffusionAPIModule:
		return image_info.get_image_info_from_result(result)
	else:
		l.g("Tried to use 'get_image_info_from_result' but api has no image info module")
		return {}


# CONTROLNET


func queue_controlnet_to_bake(dict: Dictionary, type: String):
	if dict == null:
		return
	
	var type_array = controlnet_to_bake.get(type)
	if type_array is Array:
		type_array.append(dict.duplicate(true))
	else:
		l.g("Can't bake controlnet of type '" + type + "', type not registered")


func bake_pending_controlnets(_cue: Cue = null):
	if controlnet is DiffusionAPIModule:
		controlnet.bake_pending_controlnets()
	else:
		l.g("Tried to use 'bake_pending_controlnets' but api has no controlnet module")


func preprocess(response_object: Object, response_method: String, image_data: ImageData, 
preprocessor_name: String):
	if controlnet is DiffusionAPIModule:
		controlnet.preprocess(response_object, response_method, image_data, preprocessor_name)
	else:
		l.g("Tried to use 'preprocess' but api has no controlnet module")


func get_preprocessed_image(result, preprocessor_name: String = '') -> ImageData:
	if controlnet is DiffusionAPIModule:
		return controlnet.get_preprocessed_image(result, preprocessor_name)
	else:
		l.g("Tried to use 'get_preprocessed_image' but api has no controlnet module")
		return null


# REGIONAL PROMPTING


func queue_regions_to_bake(regions: Array):
	regions_to_bake.append_array(regions)


func bake_pending_regional_prompts(_cue: Cue = null):
	# this must apply pending regions to request data
	# regions_to_bake: follows the next format:
	# [ [rect2_1, data_dict1], [rect2_2, data_dict2], ... ]
	# At the beginning are the lower priority regions, at the end, the hightest
	l.g("The function 'bake_pending_regional_prompts' has not been overriden yet on Api: " + 
	name)


# SERVER MANAGEMENT


func probe_server(_current_server_address: ServerAddress):
	# checks if server is there, must signal server_probed(success: bool)
	l.g("The function 'probe_server' has not been overriden yet on Api: " + 
	name)


func refresh_data(_what: String):
	# refresh and sends any needed data, must signal data_refreshed(what_signaled) where 
	# what_signaled: Dictionary =  { what_1: success_bool_1, what_2: success_bool_2, ... }
	# What: String = api.REFRESH_*
	l.g("The function 'refresh_data' has not been overriden yet on Api: " + 
	name)


# LOCAL SERVER MANAGEMENT


func get_current_diffusion_model(_response_object: Object, _response_method: String):
	# Gets the model in use
	l.g("The function 'get_server_config' has not been overriden yet on Api: " + 
	name)
	
	
func get_diffusion_model_from_result(_server_config_result: Dictionary):
	# Extracts the model from the result of the function above
	l.g("The function 'get_diffusion_model_from_result' has not been overriden yet on Api: " + 
	name)


func set_server_diffusion_model(_model_file_name: String, _response_object: Object, 
_success_method: String, _failure_method: String):
	l.g("The function 'set_server_diffusion_model' has not been overriden yet on Api: " + 
	name)


func cancel_diffusion():
	# Currently, just used to get the model in use
	l.g("The function 'cancel_diffusion' has not been overriden yet on Api: " + 
	name)


func adjust_server():
	# checks configuration and configures server if needed, must signal
	# adjust_server(success: bool)
	l.g("The function 'adjust_server' has not been overriden yet on Api: " + 
	name)


func stop_server():
	# sends shutdown request to server, returns self for yield pruposes, 
	# must signal server_stopped() after api response
	l.g("The function 'stop_server' has not been overriden yet on Api: " + 
	name)
	return self


func refresh_paths(_data = null):
	# refresh and sends any needed path, must signal paths_refreshed() 
	# data is whatever is needed to set the appropiate paths, must have a default
	l.g("The function 'refresh_paths' has not been overriden yet on Api: " + 
	name)


func get_lora_dir() -> String:
	return SUBDIR_LORA


func get_lycoris_dir() -> String:
	return SUBDIR_LYCORIS


func get_textual_inversion_dir() -> String:
	return SUBDIR_TI


func get_checkpoints_dir() -> String:
	return SUBDIR_DIFFUSION_MODELS


func get_controlnet_dir() -> String:
	return SUBDIR_CONTROLNET_MODELS


func get_installation_dir() -> String:
	return Cue.new(Consts.ROLE_SERVER_MANAGER, "get_full_installation_path").execute()






# DEBUG


func get_request_data() -> Dictionary:
	return request_data.duplicate(true)


func get_request_data_no_images(_custom_data: Dictionary = {}) -> Dictionary:
	# This function should return an dictionary with the parameters but no images in it
	l.g("The function 'get_request_data_no_images' has not been overriden yet on Api: " + 
	name)
	return {}


func get_request_data_no_images_no_prompts(_custom_data: Dictionary = {}) -> Dictionary:
	# This function should return an dictionary with the parameters but no images nor prompts in it
	l.g("The function 'get_request_data_no_images_no_prompts' has not been overriden yet on Api: " + 
	name)
	return {}


static func debug_scrub_dict_key_string(dictionary: Dictionary, key: String, allow_empty: bool):
	if not dictionary.has(key):
		dictionary[key] = "[no key]"
		
	var aux = dictionary.get(key, '')
	var sufix: String = ''
	if aux is Array and aux.size() >= 1:
		aux = aux[0]
		sufix = "array, "
	
	if aux is String:
		if aux.strip_edges().empty() and not allow_empty:
			dictionary[key] = sufix + "[empty]"
		elif sufix.empty():
# warning-ignore:return_value_discarded
			dictionary.erase(key)
		else:
			dictionary[key] = sufix + "[valid value]"
	else:
		dictionary[key] = sufix + "[not a string: " + str(typeof(aux)) + " -> " + str(aux) + "]"



# OTHER


func apply_safe_mode(_cue: Cue = null):
	# Currently not in use
	# Just here in case a formal or an all-ages-friendly presentation occurs
	# This eliminates things from the prompt and add stuff to the negative prompt to make it SFW
	# It's not needed to override this
	pass



class ConfigReport extends Reference:
	var report: Dictionary = {}
	enum {
		GET,
		GET_VALUE,
		SET,
		SET_VALUE
	}
	var enum_amount = 4
	
	func add(config_name: String):
		var entry = []
		entry.resize(enum_amount)
		set_at_array_pos(entry, GET, false)
		set_at_array_pos(entry, SET, false)
		report[config_name] = entry
		return entry
	
	
	func success_get(config_name: String, value, optimal_value):
		set_at_array_pos(_get_entry(config_name), GET, true)
		set_at_array_pos(_get_entry(config_name), GET_VALUE, value)
		set_at_array_pos(_get_entry(config_name), SET_VALUE, optimal_value)
		if value == optimal_value:
			set_at_array_pos(_get_entry(config_name), SET, null)
	
	
	func success_set(config_name: String, value = null):
		set_at_array_pos(_get_entry(config_name), SET, true)
		if value != null:
			set_at_array_pos(_get_entry(config_name), SET_VALUE, value)
	
	
	func _get_entry(config_name: String) -> Array:
		var resul = report.get(config_name, null)
		if resul == null:
			resul = add(config_name)
		
		return resul
	
	
	func _to_string():
		var resul = ''
		var aux: String
		for key in report:
			aux = str(report[key]).strip_edges()
			aux = aux.substr(1, aux.length() - 2) 
			resul += "\t" + key + ": \t" + aux + "\n"
		
		return resul
	
	func set_at_array_pos(array: Array, pos: int, value):
		if pos >= array.size():
			array.resize(pos + 1)
		
		array[pos] = value
		return array
