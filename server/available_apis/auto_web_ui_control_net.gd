extends DiffusionAPIModule

const CONTROLNET_DICT_KEY = "controlnet"
const CONTROLNET_ARGS_KEY = "args"
const ADDRESS_CONTROLNET_PREPROCESS = "/controlnet/detect"

var type_bgs: Dictionary = {
	Consts.CN_TYPE_CANNY: Color.black,
	Consts.CN_TYPE_LINEART: Color.black,
	Consts.CN_TYPE_MLSD: Color.black,
	Consts.CN_TYPE_SOFTEDGE: Color.black,
	Consts.CN_TYPE_OPENPOSE: Color.black,
	Consts.CN_TYPE_DEPTH: Color.black,
	Consts.CN_TYPE_NORMAL: Color.mediumpurple,
}

# The controlnet_dict goes inside and array as value of the controlnet_dict_key
# like this:	 CONTROLNET_DICT_KEY: [controlnet_dict]
# This applies to both txt2img and im2img dictionaries
# Removed keys: guidance, mask, guessmode, threshold_a, threshold_b
var controlnet_dict: Dictionary = {
	"input_image": "",
	"module": "None",
	"model": "",
	"weight": 1,
	#"resize_mode": "Just Resize", # this is not configurable, this program will resize it
	#"lowvram": false, # advanced mode only, if needed
	#"processor_res": 512, # this is only in if applying the preprocessor to the input_image
	"guidance_start": 0, # advanced mode only
	"guidance_end": 1, # advanced mode only
	#"pixel_perfect": false, # advance mode only, if needed
	"control_mode": 2, # 0 = balanced, 1 = prompt more important, 2 = controlnet more important
}


func bake_pending_controlnets():
	if api.controlnet_to_bake.empty():
		return
	
	var height = api.request_data.get("height", 512)
	var width = api.request_data.get("width", 512)
	var control_net_array
	var controlnet_to_bake = api.controlnet_to_bake
	for controlnet_type in controlnet_to_bake.keys():
		control_net_array = controlnet_to_bake.get(controlnet_type)
		if control_net_array is Array and not control_net_array.empty():
			_bake_one_controlnet_type(control_net_array, width, height, controlnet_type)
			control_net_array.resize(0) # We empty the array since this was already added


func _bake_one_controlnet_type(dictionaries: Array, width: int, height: int, type: String):
	var resul: Dictionary = controlnet_dict.duplicate()
	for key in resul.keys():
		match key:
			"input_image":
				resul[key] = api.blend_images_at_dictionaries_key(
						key, dictionaries, width, height, false, type_bgs.get(type, null)
						)
			"weight", "guidance_start", "guidance_end":
				resul[key] = api.average_nums_at_dictionaries_key(
						key, dictionaries, resul[key]
						)
			_:
				resul[key] = api.overlap_values_at_dictionaries_key(
						key, dictionaries, resul[key]
						)
	
# warning-ignore:return_value_discarded
	resul.erase("module") # keeping module will cause it to fail
	_add_controlnet_to_data(resul)


func _add_new_controlnet_to_data() -> Dictionary:
	var new_control_net = controlnet_dict.duplicate()
	_add_controlnet_to_data(new_control_net)
	return new_control_net


func _add_controlnet_to_data(dictionary: Dictionary):
	var always_on_scripts_dict: Dictionary = api.request_data[Consts.I_ALWAYS_ON_SCRIPTS]
	if not always_on_scripts_dict.has(CONTROLNET_DICT_KEY):
		always_on_scripts_dict[CONTROLNET_DICT_KEY] = {CONTROLNET_ARGS_KEY: []}
	
	always_on_scripts_dict[CONTROLNET_DICT_KEY][CONTROLNET_ARGS_KEY].append(dictionary)


func remove_images_from_request_data(data_copy: Dictionary) -> Dictionary:
	var always_on_scripts_dict: Dictionary = data_copy[Consts.I_ALWAYS_ON_SCRIPTS]
	var control_nets_array = always_on_scripts_dict.get(CONTROLNET_DICT_KEY, {})
	control_nets_array = control_nets_array.get(CONTROLNET_ARGS_KEY, [])
	for dictionary in control_nets_array:
		if dictionary is Dictionary:
			api.debug_scrub_dict_key_string(dictionary, "input_image", false)
	
	return data_copy


func remove_controlnet_images_from_result(result, images_base64: Array) -> Array:
	# We extact the controlnet array
	var controlnet_array = result.get('parameters', null)
	controlnet_array = controlnet_array.get(Consts.I_ALWAYS_ON_SCRIPTS, null)
	var extra_images_num: int = 0
	var is_cn_array: bool = false
	if controlnet_array is Dictionary:
		controlnet_array = controlnet_array.get(CONTROLNET_DICT_KEY, null)
	if controlnet_array is Dictionary:
		controlnet_array = controlnet_array.get(CONTROLNET_ARGS_KEY, null)
		is_cn_array = true
	if is_cn_array and controlnet_array is Array:
		# We remove the controlnet images
		extra_images_num = controlnet_array.size()
		for _i in range(extra_images_num):
			images_base64.pop_back()
	
	return images_base64


func preprocess(response_object: Object, response_method: String, image_data: ImageData, 
preprocessor_name: String):
	if not is_instance_valid(response_object):
		l.g("Can't preprocess image, invalid response object. Type: " + preprocessor_name, 
				l.WARNING)
	
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = api.server_address.url + ADDRESS_CONTROLNET_PREPROCESS
	var data = {
		Consts.PREP_ONLY_MODULE: preprocessor_name,
		Consts.PREP_ONLY_INPUT_IMAGES: [image_data.base64],
		Consts.PREP_ONLY_RESOLUTION: image_data.texture.get_width(),
	}
	
	# The next code notifies the server_state_indicator for a state change 
	DiffusionServer.set_state(Consts.SERVER_STATE_PREPROCESSING)
	api_request.api_post(url, data)


func get_preprocessed_image(result, preprocessor_name: String = '') -> ImageData:
	var images = result.get('images')
	var image_data: ImageData = null
	if images is Array and not images.empty():
		image_data = ImageData.new("preprocessed_image_" + preprocessor_name).load_base64(
			images[0], 
			ImageData.PNG)
	
	return image_data


func apply_controlnet_parameters(parameters: Dictionary): 
	# the config lies in the cue's dictionary (aka options)
	var request_data_controlnet = _add_new_controlnet_to_data()
	request_data_controlnet.erase(Consts.CN_MODULE)
	_merge_dict(request_data_controlnet, parameters)


func _merge_dict(base_dict: Dictionary, overwrite_dict: Dictionary):
	base_dict.merge(overwrite_dict, true)
