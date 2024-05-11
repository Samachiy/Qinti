extends ModifierMode

var config: Dictionary
var raw_info: Dictionary = {}



func select_mode():
	if selected:
		return
	selected = true
	Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "open_board").args([self]).execute()
	if data_cue == null:
		Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "set_image").args([image_data]).execute()
		if raw_info.empty():
			DiffusionServer.request_image_info(self, "_on_png_info_received", image_data.base64)
		else:
			_on_png_info_received(raw_info) # DELETE if we really don't need it, check that api reestruture works fine first
	else:
		Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "set_image").args([image_data]).execute()
		data_cue.clone().execute()


func deselect_mode():
	selected = false
	data_cue = Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "get_data_cue").execute()
	config = Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "get_config").execute()


func prepare_mode():
	if is_inside_tree() and data_cue == null:
		DiffusionServer.request_image_info(self, "_on_png_info_received", image_data.base64)


func clear_board():
	Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "clear").execute()


func _on_same_type_modifier_toggled():
	pass # Nothing to do here, override successful


func apply_to_api(_api):
	if selected or data_cue == null:
		data_cue = Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "get_data_cue").execute()
		config = Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "get_config").execute()
	
	var prompt_mode = data_cue.get_at(2)
	var prompt = [
			config.get(Consts.I_PROMPT, null), 
			config.get(Consts.I_NEGATIVE_PROMPT, null)]
# warning-ignore:return_value_discarded
	config.erase(Consts.I_PROMPT)
# warning-ignore:return_value_discarded
	config.erase(Consts.I_NEGATIVE_PROMPT)
	
	match prompt_mode:
		Consts.IMG_INFO_PROMPT_MODE_APPEND_PROMPT:
			Cue.new(Consts.ROLE_API, "apply_parameters").opts(config).execute()
			Cue.new(Consts.ROLE_API, "add_to_prompt").args(prompt).execute()
		Consts.IMG_INFO_PROMPT_MODE_REPLACE_PROMPT:
			Cue.new(Consts.ROLE_API, "apply_parameters").opts(config).execute()
			Cue.new(Consts.ROLE_API, "replace_prompt").args(prompt).execute()
		_:
			l.g("Not a valid prompt mode '" + prompt_mode + "' in image info modifier")


func _on_png_info_received(result):
	DiffusionServer.api.get_image_info_from_result(result)
	# Results format
	# {
	# "info": "string",
	# "items": {}
	# }
	if not result is Dictionary:
		return
	
	raw_info = result
#	var formatted_info = Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "process_raw_info"
#			).args([info_translations]
#			).opts(raw_info
#			).execute()
	var formatted_info = DiffusionServer.api.get_image_info_from_result(result)
	data_cue = Cue.new(Consts.ROLE_CONTROL_PNG_INFO, 'set_data_cue').args([
			formatted_info, 
			{}, 
			Consts.IMG_INFO_PROMPT_MODE_REPLACE_PROMPT,
#			raw_info])
			])
	
	if selected:
		Cue.new(Consts.ROLE_CONTROL_PNG_INFO, "set_image").args([image_data]).execute()
		data_cue.clone().execute()





