extends ModifierMode

class_name ControlnetModifierMode

export(Color) var background_color = Color.black

var layer_id: String = ''
var pending_preprocessor: ImageData = null
var preprocessor_material: Material = null
var controller_role: String = ''
var cn_model_id: String = ''
var config_cue: Cue = null
var cn_model_type = ''
var cn_model_search_string = ''
var undoredo_data: Canvas2DUndoQueue = null
var is_downloading_model: bool = false

func select_mode():
	if selected:
		return
	selected = true
	Cue.new(controller_role, "open_board").args([self]).execute()
	layer_id = Cue.new(controller_role, 'prepare_layer').args([layer_id]).execute()
	
	# There's no need to do special check with undoredo_data since those checks are already
	# taken care on the controller side (in base_controller.gd)
	undoredo_data = Cue.new(controller_role, "set_undoredo_data").args([undoredo_data]).execute()
	
	if data_cue == null:
		if pending_preprocessor == null:
			# if the selected mode changes when modifier IS selected
			Cue.new(controller_role, "get_preprocessor").args(
					[image_data, self]).execute()
		else:
			# if the selected mode changes when modifier is NOT selected
			Cue.new(controller_role, "set_preprocessor").args(
					[pending_preprocessor]).execute()
	else:
		data_cue.clone().execute()
	
	Cue.new(controller_role, "update_overlay_underlay").args([name, owner]).execute()


func deselect_mode():
	undoredo_data = Cue.new(controller_role, "get_undoredo_data").execute()
	data_cue = Cue.new(controller_role, "get_data_cue").execute()
	active_image = Cue.new(controller_role, "get_active_image").execute()
	config_cue = Cue.new(controller_role, "get_cn_config_cue").args(
			[active_image, false]).execute()
	Cue.new(controller_role, "deselect_tools").execute()
	selected = false


func prepare_mode():
	if DiffusionServer.get_state() != Consts.SERVER_STATE_READY:
		if not DiffusionServer.is_connected("state_changed", self, "_on_server_state_changed"):
			var e = DiffusionServer.connect("state_changed", self, "_on_server_state_changed")
			l.error(e, l.CONNECTION_FAILED)
		return
	
	if get_control_net_model_name().empty():
		is_downloading_model = true
		DiffusionServer.downloader.connect(
				"downloads_finished", self, "_on_control_net_model_downloaded", 
				[cn_model_search_string])
	
	Cue.new(controller_role, "get_preprocessor").args([
			image_data,
			self,
			"_on_image_preprocessed"
	]).execute()


func _on_server_state_changed(_prev_state: String, new_state: String):
	if new_state == Consts.SERVER_STATE_READY:
		if not is_prepared:
			prepare_mode()


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
		var error = DiffusionServer.connect(
				"local_controlnet_models_refreshed", 
				self, 
				"_on_control_net_models_refreshed", 
				[cn_model_search_string])
		l.error(error, l.CONNECTION_FAILED)
		DiffusionServer.refresh_data(DiffusionAPI.REFRESH_CONTROLNET_MODELS_LOCAL)
	else:
		prepare_mode()
	
	DiffusionServer.disconnect(
			"controlnet_models_refreshed", self, "_on_local_control_net_models_refreshed")


func _on_local_control_net_models_refreshed(cn_model_string):
	if cn_model_string != cn_model_search_string:
		# We confirm that we are talking to the right modifier
		return
	
	if get_control_net_model_name(false).empty():
		l.g("Failure to download control net model at modifier: " + name)
	else:
		prepare_mode()
	
	DiffusionServer.disconnect(
			"controlnet_models_refreshed", self, "_on_control_net_models_refreshed")
		


func clear_board():
	Cue.new(controller_role, "clear").execute()


func _on_same_type_modifier_toggled():
	Cue.new(controller_role, "update_overlay_underlay").args([name, owner]).execute()


func apply_to_api(api):
	if selected:
		active_image = Cue.new(controller_role, "get_active_image").execute()
		config_cue = Cue.new(controller_role, "get_cn_config_cue").args(
				[active_image, false]).execute()
	
	if active_image == null:
		config_cue = Cue.new(controller_role, "get_cn_config_cue").args(
				[pending_preprocessor.image]).execute()
	elif config_cue == null:
		config_cue = Cue.new(controller_role, "get_cn_config_cue").args(
				[active_image]).execute()
	
	_apply_cue_to_api(config_cue, api)


func _apply_cue_to_api(cue_to_apply: Cue, api):
	var control_net_model = get_control_net_model_name()
	if control_net_model.empty():
		l.g("Canceling modifier of type: '" + name + "', model has not been downloaded yet. " +
				"Currently downloading the model, please try again after the download ends.")
	cue_to_apply.add_opt(Consts.CN_MODEL, get_control_net_model_name())
	if api.has_method("queue_controlnet_to_bake"):
		api.queue_controlnet_to_bake(cue_to_apply._options, cn_model_type)


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


func blend_active_image_with_bg() -> Image:
	return ImageProcessor.add_background_to_image(active_image, background_color)


func _on_image_preprocessed(result):
	# We set the prepared related variable and stuff
	is_prepared = true
	if DiffusionServer.is_connected("state_changed", self, "_on_server_state_changed"):
		DiffusionServer.disconnect("state_changed", self, "_on_server_state_changed")
	
	# We extract the image ansd set it accordingly
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
			Consts.HELP_DESC_IMAGE_PREPROCESSED]).execute()
	var images = result.get('images')
	var image_data: ImageData
	if not images is Array or images.empty():
		DiffusionServer.mark_generation_available()
		return
	
	image_data = ImageData.new("preprocessed_image_" + name).load_base64(
			images[0], 
			ImageData.PNG)
	
	if preprocessor_material != null:
		ImageProcessor.process_image(
				image_data.image, 
				preprocessor_material, 
				self, 
				"_on_image_processed")
	else:
		pending_preprocessor = image_data
		restore_image_data = pending_preprocessor
		DiffusionServer.mark_generation_available()
		if selected:
			Cue.new(controller_role, "set_preprocessor").args(
					[pending_preprocessor]).execute()


func get_active_image() -> Image:
	if active_image != null:
		return active_image
	elif pending_preprocessor != null:
		return pending_preprocessor.image
	else:
		return null


func _on_image_processed(result: Image):
	DiffusionServer.mark_generation_available()
	pending_preprocessor = ImageData.new("preprocessed_image_" + name).load_image_object(result)
	restore_image_data = pending_preprocessor
	if selected:
		Cue.new(controller_role, "set_preprocessor").args(
				[pending_preprocessor]).execute()
