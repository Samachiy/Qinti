extends ControlnetController

onready var preprocessors_basic = $Container/Configs/ControlNetConfigs/LineartTypeBasic
onready var preprocessors_advan = $Container/Configs/ControlNetConfigs/LineartTypeAdvanced

var canvas_material = preload("res://ui/shaders/invert_colors_material.tres")

var normal_colors: bool = true
var overlay_underlay_material_normal = preload("res://ui/shaders/invert_colors_material.tres")
var overlay_underlay_material_original = null

var type_translations: Dictionary = {
	Consts.CNPREP_LINEART_REALISTIC: Consts.CN_TYPE_LINEART,
	Consts.CNPREP_LINEART_COARSE: Consts.CN_TYPE_LINEART,
	Consts.CNPREP_LINEART_ANIME: Consts.CN_TYPE_LINEART,
	Consts.CNPREP_CANNY: Consts.CN_TYPE_CANNY,
	Consts.CNPREP_MLSD: Consts.CN_TYPE_MLSD,
	Consts.CNPREP_SOFTEDGE_PIDINET_SAFE: Consts.CN_TYPE_SOFTEDGE,
	Consts.CNPREP_SOFTEDGE_HED_SAFE: Consts.CN_TYPE_SOFTEDGE,
}


func _ready():
	# Configuring inherited varaibles
	cn_model_type = Consts.CN_TYPE_LINEART
	preprocessor_material = preload("res://ui/shaders/black_to_alpha_material.tres")
	texture_material = CanvasItemMaterial.new()
	texture_material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	selected_preprocessor = Consts.CNPREP_LINEART_REALISTIC
	
	# Setting up preprocessor combobox
	preprocessors_basic.clear()
	preprocessors_advan.clear()
	add_preprocessor_to_list(Consts.CNPREP_LINEART_REALISTIC, true)
	add_preprocessor_to_list(Consts.CNPREP_LINEART_COARSE, true)
	add_preprocessor_to_list(Consts.CNPREP_LINEART_ANIME, true)
	add_preprocessor_to_list(Consts.CNPREP_CANNY, true)
	add_preprocessor_to_list(Consts.CNPREP_MLSD, false)
	add_preprocessor_to_list(Consts.CNPREP_SOFTEDGE_PIDINET_SAFE, false)
	add_preprocessor_to_list(Consts.CNPREP_SOFTEDGE_HED_SAFE, false)
	if not preprocessors_advan.select_flag_value():
		preprocessors_advan.select_by_label(Consts.CNPREP_LINEART_REALISTIC)
	
	Tutorials.subscribe(self, Tutorials.TUTM2)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM2:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM2_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM2_USE, [])
			if preprocessors_advan.visible:
				tutorial_seq.add_tr_named_step(Tutorials.TUTM2_TYPES, [preprocessors_advan])
			elif preprocessors_basic.visible:
				tutorial_seq.add_tr_named_step(Tutorials.TUTM2_TYPES, [preprocessors_basic])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_CONTROLNET_WEIGHT, 
					[cn_config.weight])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_MOD_VISIBILITY, 
					[board_owner.overunderlay_tool])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_MOD_VISIBILITY_CONFIG, 
					[board_owner.overunderlay_tool])


func add_preprocessor_to_list(preprocessor: String, is_basic: bool):
	var prep_name = preprocessor.capitalize() # will be used as translation key
	var prep_id = preprocessor # will return this to send to server
	if is_basic:
		preprocessors_basic.add_labeled_item(prep_name, prep_id)
	preprocessors_advan.add_labeled_item(prep_name, prep_id)


func update_colors(_cue: Cue = null):
	var layer = canvas.select_layer(layer_name)
	if layer == null:
		return
	
	if normal_colors:
		canvas.grid.set_as_solid_background(Color.white)
		layer.set_layer_material(canvas_material)
		overlay_underlay_material = overlay_underlay_material_normal
	else:
#		if layer.material != null:
		canvas.grid.set_as_solid_background(Color.black)
		layer.set_layer_material(null)
		overlay_underlay_material = overlay_underlay_material_original
	
	canvas.lay.set_material(canvas.MODIFIERS_OVERLAY, overlay_underlay_material)
	canvas.lay.set_material(canvas.MODIFIERS_UNDERLAY, overlay_underlay_material)


func _on_InvertColors_toggled(button_pressed):
	normal_colors = button_pressed
	update_colors()


func get_cn_config(cue: Cue = null):
	# We override it in order to add the selected cn_model_type
	var config_cue = .get_cn_config(cue)
	config_cue.args([cn_model_type])
	return config_cue


func get_data_cue(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	if layer_name.empty():
		return null
	
	var cue = Cue.new(Consts.ROLE_CONTROL_LINEART, 'set_data_cue')
	
	cue.args([
		canvas.display_area,
		layer_name,
		normal_colors,
		])
	
	return cue


func set_data_cue(cue: Cue):
	clear()
	var display_area = cue.get_at(0, Rect2(Vector2.ZERO, Vector2(512, 512)))
	var layer_name_ = cue.get_at(1, '')
	var normal_colors_ = cue.get_at(2, true)
	prepare_layer(Cue.new('', '').args([layer_name_]))
	normal_colors = normal_colors_
	update_colors()
	canvas.display_area = display_area
	canvas.fit_to_rect2(display_area)


func _on_LineartTypeBasic_option_selected(label_id, _index_id):
	if selected_preprocessor == label_id:
		return
	
	selected_preprocessor = label_id
	preprocessors_advan.select_by_label(label_id)
	reset_layer()
	get_preprocessor(Cue.new('', ''))


func _on_LineartTypeAdvanced_option_selected(label_id, _index_id):
	if selected_preprocessor == label_id:
		return
	
	cn_model_type = type_translations.get(label_id, Consts.CN_TYPE_LINEART)
	selected_preprocessor = label_id
	preprocessors_basic.select_by_label(label_id)
	reset_layer()
	if modifier is ModifierMode:
		get_preprocessor(Cue.new('', ''))
