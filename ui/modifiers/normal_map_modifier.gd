extends ControlnetModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_NORMAL_MAP
	cn_model_type = Consts.CN_TYPE_NORMAL
	cn_model_search_string = cn_model_type

