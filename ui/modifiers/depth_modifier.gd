extends ControlnetModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_DEPTH
	cn_model_type = Consts.CN_TYPE_DEPTH
	cn_model_search_string = cn_model_type
	preprocessor_material = preload("res://ui/shaders/black_to_alpha_material.tres")


func select_mode():
	.select_mode()
	Cue.new(Consts.ROLE_CONTROL_DEPTH, "update_canvas_background").execute()
