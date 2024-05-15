extends ControlnetNoCanvasModifierMode


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
