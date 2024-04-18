extends ControlnetController

onready var face_checkbox = $Container/Configs/ControlNetConfigs/HBoxContainer/Face
onready var hands_checkbox = $Container/Configs/ControlNetConfigs/HBoxContainer/Hands

var preprocess_face: bool = false
var preprocess_hands: bool = false


func _ready():
	# Configuring inherited varaibles
	cn_model_type = Consts.CN_TYPE_OPENPOSE
	preprocessor_material = preload("res://ui/shaders/black_to_alpha_color_material.tres")
	texture_material = CanvasItemMaterial.new()
	texture_material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	selected_preprocessor = Consts.CNPREP_OPENPOSE
	Tutorials.subscribe(self, Tutorials.TUTM8)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM8:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM8_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM8_FACE_HANDS, 
					[face_checkbox, hands_checkbox])
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
	
	var cue = Cue.new(Consts.ROLE_CONTROL_POSE2D, 'set_data_cue')
	
	cue.args([
		canvas.display_area,
		layer_name,
		preprocess_face,
		preprocess_hands,
		])
	
	return cue


func set_data_cue(cue: Cue):
	clear()
	var display_area = cue.get_at(0, Rect2(Vector2.ZERO, Vector2(512, 512)))
	var layer_name_ = cue.get_at(1, '')
	preprocess_face = cue.bool_at(2, false)
	preprocess_hands = cue.bool_at(3, false)
	prepare_layer(Cue.new('', '').args([layer_name_]))
	canvas.display_area = display_area
	canvas.fit_to_rect2(display_area)
	face_checkbox.pressed = preprocess_face
	hands_checkbox.pressed = preprocess_hands


func update_canvas_background(_cue: Cue = null):
	canvas.grid.set_as_solid_background(Color.black)


func _on_Face_toggled(button_pressed):
	preprocess_face = button_pressed
	update_preprocessor()


func _on_Hands_toggled(button_pressed):
	preprocess_hands = button_pressed
	update_preprocessor()


func update_preprocessor():
	if preprocess_face and preprocess_hands:
		change_preprocessor(Consts.CNPREP_OPENPOSE_ALL)
	elif preprocess_face:
		change_preprocessor(Consts.CNPREP_OPENPOSE_PLUS_FACE)
	elif preprocess_hands:
		change_preprocessor(Consts.CNPREP_OPENPOSE_PLUS_HAND)
	else:
		change_preprocessor(Consts.CNPREP_OPENPOSE)


func change_preprocessor(new_preprocessor: String):
	if selected_preprocessor == new_preprocessor:
		return
	
	selected_preprocessor = new_preprocessor
	reset_layer()
	get_preprocessor(Cue.new('', ''))
