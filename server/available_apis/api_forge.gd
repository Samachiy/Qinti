extends AutoWebUI_API

class_name Forge_API

const ADDRESS_CONTROLNET_PREPROCESS = "/controlnet/detect"

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



func refresh_data(what: String):
	var is_all = what == REFRESH_ALL
	var resul = {}
	var success
	if is_all or what == REFRESH_CONTROLNET_MODELS:
		var models = Cue.new(Consts.ROLE_FILE_PICKER, "get_file_paths").args([
				get_controlnet_dir(), ".pth"]).execute()
		for i in range(models.size()):
			models[i] = models[i].get_basename().get_file()

		DiffusionServer.controlnet_models = models
		resul[REFRESH_CONTROLNET_MODELS_LOCAL] = success
	
	if is_all or what == REFRESH_SAMPLERS:
		var api_request = APIRequest.new(self, "_on_samplers_refreshed", self)
		var url = server_address.url + ADDRESS_GET_SAMPLERS
		success = yield(api_request.api_get(url), "api_request_finished")
		resul[REFRESH_SAMPLERS] = success
	
	if is_all or what == REFRESH_UPSCALERS:
		var api_request = APIRequest.new(self, "_on_upscalers_refreshed", self)
		var url = server_address.url + ADDRESS_GET_UPSCALERS
		success = yield(api_request.api_get(url), "api_request_finished")
		resul[REFRESH_UPSCALERS] = success
	
	if is_all or what == REFRESH_MODELS:
		var api_request = APIRequest.new(self, "_on_diffusion_models_refreshed", self)
		var url = server_address.url + ADDRESS_REFRESH_DIFFUSION_MODELS
		success = yield(api_request.api_post(url, {}), "api_request_finished")
		resul[REFRESH_MODELS] = success
	
	emit_signal("data_refreshed", resul)
