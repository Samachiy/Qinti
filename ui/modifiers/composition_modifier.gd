extends ControlnetModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_COMPOSITION
	cn_model_type = Consts.CN_TYPE_SEG
	cn_model_search_string = cn_model_type

