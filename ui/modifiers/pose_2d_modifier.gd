extends ControlnetModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_POSE2D
	cn_model_type = Consts.CN_TYPE_OPENPOSE
	cn_model_search_string = cn_model_type
	preprocessor_material = preload("res://ui/shaders/black_to_alpha_color_material.tres")


func select_mode():
	.select_mode()
	Cue.new(Consts.ROLE_CONTROL_POSE2D, "update_canvas_background").execute()
