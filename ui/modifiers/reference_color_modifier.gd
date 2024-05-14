extends ControlnetNoCanvasModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_COLOR
	cn_model_type = Consts.CN_TYPE_COLOR
	cn_model_search_string = cn_model_type
