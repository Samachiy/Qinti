extends DiffusionAPIModule


const CONTROLNET_DICT_KEY = "controlnet"
const CONTROLNET_ARGS_KEY = "args"
const ADDRESS_CONTROLNET_PREPROCESS = "/controlnet/detect"


# COPIED OVER FROM auto_web_ui_control_net.gd
# This is done so as to not create inheritance on something extremelly small and 
# specific that on top of that has a different way of functioning in certain aspects


func bake_pending_controlnets():
	if api.controlnet_to_bake.empty():
		return
	
	var height = api.request_data.get("height", 512)
	var width = api.request_data.get("width", 512)
	var controlnet_data = api.get_controlnet_data(width, height)
	for value in controlnet_data.values():
		_add_controlnet_to_data(value)
	
	return


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


func get_preprocessed_image(result, preprocessor_name: String = '') -> ImageData:
	var images = result.get('images')
	var image_data: ImageData = null
	if images is Array and not images.empty():
		image_data = ImageData.new("preprocessed_image_" + preprocessor_name).load_base64(
			images[0], 
			ImageData.PNG)
	
	return image_data


# ORIGINAL/UNIQUE FUNCTIONS FOR FORGE


var preprocessors_translation_dict = {
	Consts.CNPREP_LINEART_REALISTIC: "lineart_realistic",
	Consts.CNPREP_SOFTEDGE_PIDINET_SAFE: "softedge_pidisafe",
	Consts.CNPREP_SOFTEDGE_HED_SAFE: "softedge_hedsafe",
	Consts.CNPREP_DEPTH_MIDAS: "depth_midas",
	Consts.CNPREP_NORMAL_BAE: "normalbae",
	Consts.CNPREP_NORMAL_MAP: "normal_midas",
	Consts.CNPREP_SEG_OFADE20K: "seg_ofade20k",
	Consts.CNPREP_SEG_OFCOCO: "seg_ofcoco",
	Consts.CNPREP_SEG_UFADE20K: "seg_ufade20k",
	Consts.CNPREP_OPENPOSE_ALL: "dw_openpose_full",
	Consts.CNPREP_SCRIBBLE_PIDINET: "scribble_pidinet",
	Consts.CNPREP_INVERT: "invert (from white bg & black line)",
}


func preprocess(response_object: Object, response_method: String, failure_method: String, 
image_data: ImageData, preprocessor_name: String):
	if not is_instance_valid(response_object):
		l.g("Can't preprocess image, invalid response object. Type: " + preprocessor_name, 
				l.WARNING)
	
	var api_request = APIRequest.new(response_object, response_method, self)
	api_request.connect_on_request_failed(DiffusionServer, failure_method)
	var url = api.server_address.url + ADDRESS_CONTROLNET_PREPROCESS
	var data = {
		Consts.PREP_ONLY_MODULE: translate_preprocessor(preprocessor_name),
		Consts.PREP_ONLY_INPUT_IMAGES: [image_data.base64],
		Consts.PREP_ONLY_RESOLUTION: image_data.texture.get_width(),
	}
	
	# The next code notifies the server_state_indicator for a state change 
	DiffusionServer.set_state(Consts.SERVER_STATE_PREPROCESSING)
	api_request.api_post(url, data)


func translate_preprocessor(preprocessor_name: String):
	var translation = preprocessors_translation_dict.get(preprocessor_name, '')
	if translation.empty():
		return preprocessor_name
	else:
		return translation
