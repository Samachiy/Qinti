extends ControlnetNoCanvasModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_REFERENCE
	cn_model_type = Consts.CN_TYPE_REFERENCE
	cn_model_search_string = ""
