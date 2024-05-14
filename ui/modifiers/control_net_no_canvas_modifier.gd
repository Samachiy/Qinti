extends ModifierMode

class_name ControlnetNoCanvasModifierMode

export(Color) var background_color = Color.black

var layer_id: String = ''
var controller_role: String = ''
var cn_model_id: String = ''
var config_dict: Dictionary = {}
var cn_model_type = ''
var cn_model_search_string = ''
var is_downloading_model: bool = false

func select_mode():
	if selected:
		return
	selected = true
	Cue.new(controller_role, "open_board").args([self]).execute()
	layer_id = Cue.new(controller_role, 'prepare_layer').args([layer_id]).execute()
	
	if data_cue == null:
		Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "set_image").args([image_data]).execute()
	else:
		data_cue.clone().execute()


func deselect_mode():
	data_cue = Cue.new(controller_role, "get_data_cue").execute()
	config_dict = Cue.new(controller_role, "get_cn_config").args(
			[image_data.image, false]).execute()
	Cue.new(controller_role, "deselect_tools").execute()
	selected = false


func prepare_mode():
	if get_control_net_model_name().empty():
		is_downloading_model = true
		DiffusionServer.downloader.connect(
				"downloads_finished", self, "_on_control_net_model_downloaded", 
				[cn_model_search_string])


func _on_control_net_model_downloaded(cn_model_string):
	if cn_model_string != cn_model_search_string:
		return
	
	DiffusionServer.refresh_data(DiffusionAPI.REFRESH_CONTROLNET_MODELS)
	is_downloading_model = false
	var error = DiffusionServer.connect(
			"controlnet_models_refreshed", 
			self, 
			"_on_control_net_models_refreshed", 
			[cn_model_search_string])
	l.error(error, l.CONNECTION_FAILED)


func _on_control_net_models_refreshed(cn_model_string):
	if cn_model_string != cn_model_search_string:
		# We confirm that we are talking to the right modifier
		return
	
	if get_control_net_model_name(false).empty():
		l.g("Failure to download control net model at modifier: " + name)
#		var error = DiffusionServer.connect(
#				"local_controlnet_models_refreshed", 
#				self, 
#				"_on_control_net_models_refreshed", 
#				[cn_model_search_string])
#		l.error(error, l.CONNECTION_FAILED)
#		DiffusionServer.refresh_data(DiffusionAPI.REFRESH_CONTROLNET_MODELS_LOCAL)
	else:
		prepare_mode()
	
	DiffusionServer.disconnect(
			"controlnet_models_refreshed", self, "_on_local_control_net_models_refreshed")


#func _on_local_control_net_models_refreshed(cn_model_string):
#	if cn_model_string != cn_model_search_string:
#		# We confirm that we are talking to the right modifier
#		return
#
#	if get_control_net_model_name(false).empty():
#		l.g("Failure to download control net model at modifier: " + name)
#	else:
#		prepare_mode()
#
#	DiffusionServer.disconnect(
#			"controlnet_models_refreshed", self, "_on_control_net_models_refreshed")
		


func clear_board():
	Cue.new(controller_role, "clear").execute()


func _on_same_type_modifier_toggled():
	Cue.new(controller_role, "update_overlay_underlay").args([name, owner]).execute()


func apply_to_api(api):
	if selected:
		config_dict = Cue.new(controller_role, "get_cn_config").args(
				[image_data.image, false]).execute()
	
	if config_dict.empty():
		config_dict = Cue.new(controller_role, "get_cn_config").args(
				[image_data.image]).execute()
	
	_apply_config_to_api(config_dict, api)


func _apply_config_to_api(config_to_apply: Dictionary, api):
	var control_net_model = get_control_net_model_name()
	if control_net_model.empty():
		l.g("Canceling modifier of type: '" + name + "', model has not been downloaded yet. " +
				"Currently downloading the model, please try again after the download ends.")
		return
	
	config_to_apply[Consts.CN_MODEL] = control_net_model
	if api.has_method("queue_controlnet_to_bake"):
		api.queue_controlnet_to_bake(config_to_apply, cn_model_type)


func get_control_net_model_name(download_if_missing: bool = true) -> String:
	var model: String = DiffusionServer.search_controlnet_model(cn_model_search_string)
	if not model.empty():
		# If getting the model succeds, we return it
		return model
	
	# If getting the model fails, we start try to download it
	if cn_model_type.empty():
		# If the cn_model_type is empty, we can't start download
		l.g("Couldn't find a model labeled as '" + cn_model_search_string + 
				"' nor download a model of type '" + cn_model_type + 
				"' at controller: " + name)
		return ''
	
	# Ie try the download
	model = DiffusionServer.downloader.search_controlnet_model(cn_model_search_string)
	if not model.empty() and download_if_missing:
		DiffusionServer.downloader.download_control_net(cn_model_search_string)
	
	# If we don't found the link, we return empty
	return ''




func get_active_image() -> Image:
	if image_data != null:
		return image_data.image
	else:
		return null
