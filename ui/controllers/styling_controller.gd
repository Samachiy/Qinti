extends Controller

onready var style_details = $Container/Configs/StyleDetailsViewer

var styling_data: StylingData = null


func _ready():
	Tutorials.subscribe(self, Tutorials.TUTM9)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM9:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM9_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM9_STRENGHT, 
					[style_details.strenght_slider])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM9_IS_NEGATIVE, 
					[style_details.is_negative_checkbox])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM9_EXTRA, 
					[style_details.extra_prompt])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM9_EXTRA_SLIDER, 
					[style_details.extra_strenght_slider])


func set_base_data(cue: Cue):
	# [styling_data]
	styling_data = cue.get_at(0, null)
	if styling_data == null:
		return
	
	style_details.set_data(styling_data)
	canvas.texture = styling_data.get_image_data().texture


func get_prompt_cue(_cue: Cue = null):
	var dict: Array = [
		style_details.get_positive_prompt(),
		style_details.get_negative_prompt()
	]
	return Cue.new(Consts.ROLE_API, "add_to_prompt").args(dict)


func clear(_cue: Cue = null):
	style_details.clear()


func get_data_cue(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	if styling_data == null:
		return null
	
	var cue = Cue.new(Consts.ROLE_CONTROL_STYLING, 'set_data_cue')
	cue.opts(style_details.get_data_dictionary())
	cue.args([
		styling_data,
		])
	
	return cue


func set_data_cue(cue: Cue):
	set_base_data(cue)
	style_details.set_data_dictionary(cue._options)


func _fill_menu():
	canvas.menu.add_tr_labeled_item(Consts.MENU_EDIT)


func _on_Menu_option_pressed(label_id, _index_id):
	match label_id:
		Consts.MENU_EDIT:
			Cue.new(Consts.ROLE_STYLE_EDITOR, "open").args([styling_data]).execute()
