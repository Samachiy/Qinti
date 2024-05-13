extends ControlnetModifierMode

var type_translations: Dictionary = {
	Consts.CNPREP_LINEART_REALISTIC: 'lineart',
	Consts.CNPREP_LINEART_COARSE: 'lineart',
	Consts.CNPREP_LINEART_ANIME: 'lineart',
	Consts.CNPREP_CANNY: 'canny',
	Consts.CNPREP_MLSD: 'mlsd',
	Consts.CNPREP_SOFTEDGE_PIDINET_SAFE: 'edge',
	Consts.CNPREP_SOFTEDGE_HED_SAFE: 'edge',
}

func _ready():
	controller_role = Consts.ROLE_CONTROL_LINEART
	cn_model_type = Consts.CN_TYPE_LINEART
	cn_model_search_string = cn_model_type
	preprocessor_material = preload("res://ui/shaders/black_to_alpha_material.tres")


func select_mode():
	.select_mode()
	Cue.new(Consts.ROLE_CONTROL_LINEART, "update_colors").execute()


func _apply_config_to_api(config_to_apply: Dictionary, api):
	cn_model_type = config_to_apply.get(Consts.CN_MODEL, 'lineart')
	cn_model_search_string = type_translations.get(cn_model_type, 'lineart')
	._apply_config_to_api(config_to_apply, api)

