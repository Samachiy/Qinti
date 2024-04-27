extends AutoWebUI_API

class_name Forge_API

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



func preprocess(response_object: Object, response_method: String, image_data: ImageData, 
preprocessor_name: String):
	if not is_instance_valid(response_object):
		l.g("Can't preprocess image, invalid response object. Type: " + preprocessor_name, 
				l.WARNING)
	
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = server_address.url + ADDRESS_CONTROLNET_PREPROCESS
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
