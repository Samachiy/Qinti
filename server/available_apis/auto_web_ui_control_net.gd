extends DiffusionAPIModule

const CONTROLNET_DICT_KEY = "controlnet"
const CONTROLNET_ARGS_KEY = "args"
const ADDRESS_CONTROLNET_PREPROCESS = "/controlnet/detect"

# The controlnet_dict goes inside and array as value of the controlnet_dict_key
# like this:	 CONTROLNET_DICT_KEY: [controlnet_dict]
# This applies to both txt2img and im2img dictionaries
# Removed keys: guidance, mask, guessmode, threshold_a, threshold_b
var controlnet_dict: Dictionary = {
	"enabled": true,
	"input_image": "",
	"image": "",
	"module": "None",
	"model": "",
	"weight": 1,
	#"resize_mode": "Just Resize", # this is not configurable, this program will resize it
	#"lowvram": false, # advanced mode only, if needed
	#"processor_res": 512, # this is only in if applying the preprocessor to the input_image
	"guidance_start": 0, # advanced mode only
	"guidance_end": 1, # advanced mode only
	#"pixel_perfect": false, # advance mode only, if needed
	"control_mode": 0, # 0 = balanced, 1 = prompt more important, 2 = controlnet more important
}


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
	
	#  Deprecated alias 'input_image' detected. This field will be removed on 2024-06-01Please use 'image' instead
	dictionary['image'] = dictionary['input_image'] 
# warning-ignore:return_value_discarded
	dictionary.erase('input_image')
	match dictionary.get("control_mode", 0):
		0:
			dictionary["control_mode"] = "Balanced"
		1:
			dictionary["control_mode"] = "My prompt is more important"
		2:
			dictionary["control_mode"] = "ControlNet is more important"
	
	dictionary["enabled"] = true
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
	
	var images_amount = int(result.get("batch_size", 1)) * int(result.get("n_iter", 1))
	if is_cn_array and controlnet_array is Array:
		# We remove the controlnet images
		extra_images_num = controlnet_array.size()
# warning-ignore:narrowing_conversion
		extra_images_num = min(extra_images_num, images_base64.size() - images_amount)
		for _i in range(extra_images_num):
			images_base64.pop_back()
	
	return images_base64


func preprocess(response_object: Object, response_method: String, failure_method: String, 
image_data: ImageData, preprocessor_name: String):
	
	var api_request = APIRequest.new(response_object, response_method, self)
	api_request.connect_on_request_failed(DiffusionServer, failure_method)
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
