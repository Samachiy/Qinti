extends ControlnetController

onready var preprocessor_options = $Container/Configs/ControlNetConfigs/Preprocessor


func _ready():
	# Configuring inherited varaibles
	cn_model_type = Consts.CN_TYPE_DEPTH
	preprocessor_material = preload("res://ui/shaders/black_to_alpha_material.tres")
	texture_material = CanvasItemMaterial.new()
	texture_material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	selected_preprocessor = Consts.CNPREP_DEPTH_MIDAS
	
	# Setting up preprocessor combobox
	preprocessor_options.clear()
	var prep_name = Consts.CNPREP_DEPTH_MIDAS.capitalize()
	var prep_id = Consts.CNPREP_DEPTH_MIDAS
	var default = preprocessor_options.add_labeled_item(prep_name, prep_id)
	prep_name = Consts.CNPREP_DEPTH_LERES.capitalize()
	prep_id = Consts.CNPREP_DEPTH_LERES
	preprocessor_options.add_labeled_item(prep_name, prep_id)
	prep_name = Consts.CNPREP_DEPTH_ZOE.capitalize()
	prep_id = Consts.CNPREP_DEPTH_ZOE
	preprocessor_options.add_labeled_item(prep_name, prep_id)
	if not preprocessor_options.select_flag_value():
		preprocessor_options.select(default)
	
	Tutorials.subscribe(self, Tutorials.TUTM5)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM5:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM5_DESCRIPTION, [])
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
	
	var cue = Cue.new(Consts.ROLE_CONTROL_DEPTH, 'set_data_cue')
	
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
	canvas.display_area = display_area
	canvas.fit_to_rect2(display_area)


func _on_Preprocessor_option_selected(label_id, _index_id):
	if selected_preprocessor == label_id:
		return
	
	selected_preprocessor = label_id
	reset_layer()
	get_preprocessor(Cue.new('', ''))


func update_canvas_background(_cue: Cue = null):
	canvas.grid.set_as_solid_background(Color.black)
