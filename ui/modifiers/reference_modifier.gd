extends ControlnetModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_REFERENCE
	cn_model_type = Consts.CN_TYPE_REFERENCE
	cn_model_search_string = ""


func _apply_config_to_api(config_to_apply: Dictionary, api):
	var control_net_model = ''
	
	config_to_apply[Consts.CN_MODEL] = control_net_model
	config_to_apply[Consts.CN_MODULE] = "reference_only"
	if api.has_method("queue_controlnet_to_bake"):
		api.queue_controlnet_to_bake(config_to_apply, cn_model_type)


func prepare_mode():
	# We add the image on pending_preprocessor directly since there's no
	# preprocessor to apply but we still need the program to treat the image as 
	# if it was the already preprocessed image
	pending_preprocessor = image_data
	restore_image_data = pending_preprocessor
	is_preprocessed = true
	if selected:
		Cue.new(controller_role, "set_preprocessor").args(
				[pending_preprocessor]).execute()
