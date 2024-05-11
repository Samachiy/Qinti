extends DiffusionAPIModule

const POSITIVE_PROMPT = "Positive prompt:"
const NEGATIVE_PROMPT = "Negative prompt:"
const CONFIG_DETAILS = "Steps:"

# The purpose of this dictionary is to replace the result given by the 
# png info api with item names that can be recognized by the constants in Const.gd,
# that way when loading the configuation in the image in order to generate,
# we just need to merge the configuration into the api call
var info_translations: Dictionary = {
	"cfg scale": Consts.I_CFG_SCALE,
	"denoising strength": Consts.I_DENOISING_STRENGTH,
	"ensd": Consts.SDO_ENSD,
	"hires steps": Consts.T2I_HR_SECOND_PASS_STEPS,
	"hires upscale": Consts.T2I_HR_SCALE,
	"hires upscaler": Consts.T2I_HR_UPSCALER,
	Consts.T2I_ENABLE_HR: Consts.T2I_ENABLE_HR,
	"clip skip": Consts.SDO_CLIP_SKIP,
	"model": Consts.SDO_MODEL,
	"model hash": Consts.SDO_MODEL_HASH,
	"negative prompt": Consts.I_NEGATIVE_PROMPT,
	"positive prompt": Consts.I_PROMPT,
	"sampler": Consts.I_SAMPLER_NAME,
	"seed": Consts.I_SEED,
	"size": ImageInfoController.SIZE_CONFIG_DISPLAY_NAME,
	"steps": Consts.I_STEPS
}


func request_image_info(response_object: Object, response_method: String, image_base64: String):
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = api.server_address.url + api.ADDRESS_IMAGE_INFO
	api_request.api_post(url, {Consts.OI_PNG_INFO_IMAGE: image_base64})


func get_image_info_from_result(result) -> Dictionary:
	var info = result.get('info')
	if info is String and info_translations is Dictionary:
		return format_info(info)
	elif info_translations is Dictionary:
		l.g("Can't process raw info in image controller, info: " + str(info))
		return {}
	else: 
		l.g("Can't process raw info in image controller, info_translations not a dictionary")
		return {}


func format_info(string: String) -> Dictionary:
	var resul: Dictionary = {}
	var negative_prompt_pos = string.find(NEGATIVE_PROMPT)
	var other_config_pos = string.find(CONFIG_DETAILS)
	var positive_prompt = ''
	var negative_prompt = ''
	var config_details = ''
	if other_config_pos != -1:
		config_details = string.substr(other_config_pos)
		string = string.substr(0, other_config_pos)
	if negative_prompt_pos != -1:
		positive_prompt = string.substr(0, negative_prompt_pos)
		negative_prompt = string.substr(negative_prompt_pos)
	else:
		positive_prompt = string.strip_edges()
	
	var not_formated_entries: Array = config_details.split(',')
	if not negative_prompt.empty():
		not_formated_entries.push_front(negative_prompt)
	if not positive_prompt.empty():
		not_formated_entries.push_front(POSITIVE_PROMPT + positive_prompt)
	
	_add_info_entries_to_dict(not_formated_entries, resul)
	return _translate_dict(resul, info_translations)


func _add_info_entries_to_dict(entries: Array, resul_dict: Dictionary):
	var key: String
	var value: String
	var aux: Array
	for entry in entries:
		aux = entry.split(':', false, 1)
		if aux.size() != 2:
			continue
		
		key = aux[0].strip_edges()
		value = aux[1].strip_edges()
		resul_dict[key] = value
		if "hires" in key.to_lower():
			resul_dict[Consts.T2I_ENABLE_HR] = true
	
	return resul_dict


func _translate_dict(dict: Dictionary, translations: Dictionary) -> Dictionary:
	var new_dict = {}
	var translated_key
	var other_info = ''
	for key in dict.keys():
		translated_key = translations.get(key.to_lower())
		if translated_key == null:
			l.g("Unrecognized value '" + key + "' on image info", l.INFO)
			other_info += key + ": " + dict[key] + "\n"
		else:
			new_dict[translated_key] = dict[key]
	
	if not other_info.empty():
		new_dict[ImageInfoController.OTHER_DETAILS_KEY] = other_info
	
	return new_dict
