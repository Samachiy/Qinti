extends ControlnetController


func _ready():
	# Configuring inherited varaibles
	cn_model_type = Consts.CN_TYPE_REFERENCE
	
	Tutorials.subscribe(self, Tutorials.TUTM10)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM10:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM10_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM10_EMPTY_SPACE_IS_WHITE, [])
			if canvas is Canvas2D:
				tutorial_seq.add_tr_named_step(
						Tutorials.TUTM10_EMPTY_SPACE_ADVICE, 
						[canvas.active_area_node]
				)
			else:
				tutorial_seq.add_tr_named_step(Tutorials.TUTM10_EMPTY_SPACE_ADVICE, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_CONTROLNET_WEIGHT, 
					[cn_config.weight])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_MOD_VISIBILITY, 
					[board_owner.overunderlay_tool])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_MOD_VISIBILITY_CONFIG, 
					[board_owner.overunderlay_tool])


func get_data_cue(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	if layer_name.empty():
		return null
	
	var cue = Cue.new(Consts.ROLE_CONTROL_IMG2IMG, 'set_data_cue')
	
	cue.args([
		canvas.display_area,
		layer_name,
		])
	
	return cue


func set_data_cue(cue: Cue):
	clear()
	var display_area = cue.get_at(0, Rect2(Vector2.ZERO, Vector2(512, 512)))
	var layer_name_ = cue.get_at(1, '')
	prepare_layer(Cue.new('', '').args([layer_name_]))
	if display_area is Rect2:
		canvas.display_area = display_area
		canvas.fit_to_rect2(display_area)
