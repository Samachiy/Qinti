extends ControlnetModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_SCRIBBLE
	cn_model_type = Consts.CN_TYPE_SCRIBBLE
	cn_model_search_string = cn_model_type


func deselect_mode():
	.deselect_mode()
	if owner is Modifier:
		var image_data = ImageData.new(cn_model_type + "_image")
		image_data.load_image_object(active_image)
		owner._refresh_image_data_with(image_data)
