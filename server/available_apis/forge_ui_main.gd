extends AutoWebUI_API

class_name Forge_API


func load_modules():
#	controlnet = add_module(
#			DiffusionServer.FEATURE_CONTROLNET, 
#			"res://server/available_apis/forge_ui_control_net.gd"
#	)
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
