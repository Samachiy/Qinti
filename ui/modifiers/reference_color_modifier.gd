extends ControlnetNoCanvasModifierMode


func _ready():
	controller_role = Consts.ROLE_CONTROL_COLOR
	cn_model_type = Consts.CN_TYPE_COLOR
	cn_model_search_string = cn_model_type


func apply_to_api(api):
	var gen_area_rect: Rect2 = Cue.new(Consts.ROLE_CANVAS, "get_generation_area").execute()
	var image = image_data.image
	var proportional_image: Image = image.get_rect(image.get_used_rect())
	var new_size = gen_area_rect.size
	proportional_image.resize(int(new_size.x), int(new_size.y))
	
	if selected:
		config_dict = Cue.new(controller_role, "get_cn_config").args(
				[proportional_image, false]).execute()
	
	if config_dict.empty():
		config_dict = Cue.new(controller_role, "get_cn_config").args(
				[proportional_image]).execute()
	
	_apply_config_to_api(config_dict, api)


func _on_deleted_modifier():
	pass


func _on_undeleted_modifier():
	pass


func _on_destroyed_modifier():
	pass
