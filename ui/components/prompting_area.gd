extends MarginContainer

const PREV_SEED = "prev_seed"

onready var prompt_area = $HBoxContainer/Prompting
onready var generate_button = $HBoxContainer/Buttons/Generate
onready var positive_prompt = $HBoxContainer/Prompting/PositivePrompt
onready var negative_prompt = $HBoxContainer/Prompting/NegativePrompt
onready var seed_field = $HBoxContainer/Buttons/VBoxContainer/Seed/Seed
onready var reuse_seed_button = $HBoxContainer/Buttons/VBoxContainer/Seed/Reuse
onready var rand_seed_button = $HBoxContainer/Buttons/VBoxContainer/Seed/Random
onready var model_button = $HBoxContainer/Buttons/VBoxContainer/CurrentModelThumbnail

var last_seed: int = -1
var pending_generation: bool = false

func _ready():
	Roles.request_role(self, Consts.ROLE_PROMPTING_AREA)
	yield(get_tree().current_scene, "ready")
	var e = DiffusionServer.connect("state_changed", self, "_on_server_state_changed")
	l.error(e, l.CONNECTION_FAILED)
	
	reuse_seed_button.modulate.a8 = Consts.OPPOSITE_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(
			reuse_seed_button, Consts.THEME_MODULATE_GROUP_STYLE)
	rand_seed_button.modulate.a8 = Consts.OPPOSITE_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(
			rand_seed_button, Consts.THEME_MODULATE_GROUP_STYLE)
	
	Tutorials.subscribe(self, Tutorials.TUT1)
	Tutorials.subscribe(self, Tutorials.TUT5)
	Tutorials.subscribe(self, Tutorials.TUT6)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUT1:
			var step: TutorialStep
			tutorial_seq.add_tr_named_step(Tutorials.TUT1_PROMPT, [prompt_area])
			step = tutorial_seq.add_tr_named_step(Tutorials.TUT1_GEN_BUTTON, [generate_button])
			step.cue_in_run(Cue.new(Consts.ROLE_PROMPTING_AREA, "write_prompt").args([
					"lanscape", "bad quality"
			]))
		Tutorials.TUT5:
			var mod_area = Roles.get_node_by_role(Consts.ROLE_MODIFIERS_AREA)
			tutorial_seq.add_tr_named_step(Tutorials.TUT5_LOAD, [prompt_area, mod_area])
			tutorial_seq.add_tr_named_step(Tutorials.TUT5_PARAMETERS, [mod_area])
			tutorial_seq.add_tr_named_step(Tutorials.TUT5_DEFAULTS, [])
		Tutorials.TUT6:
			var step = tutorial_seq.add_tr_named_step(Tutorials.TUT6_OPENING, [model_button])
			step.cue_in_run(Cue.new(Consts.ROLE_MODEL_SELECTOR, "close"))


func _on_server_state_changed(_prev_state: String, new_state: String):
	if new_state == Consts.SERVER_STATE_READY:
		if pending_generation:
			DiffusionServer.generate(self, "_on_image_generated")
			pending_generation = false


func generate(_cue: Cue = null):
	_on_Generate_pressed()


func _on_Generate_pressed():
	if DiffusionServer.get_state() != Consts.SERVER_STATE_READY:
		if DiffusionServer.get_state() != Consts.SERVER_STATE_GENERATING:
			pending_generation = true
		return
		
	Cue.new(Consts.ROLE_API, "clear").execute()
	add_prompt_and_seed_to_api()
	Cue.new(Consts.ROLE_CANVAS, "apply_parameters_to_api").execute()
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "apply_modifiers_to_api").execute()
	
	Cue.new(Consts.ROLE_API, "bake_pending_img2img").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_mask").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_controlnets").execute()
#	yield(Cue.new(Consts.ROLE_API, "bake_pending_regional_prompts").execute(), "completed")
	
#	if not OS.has_feature("standalone"):
#		Cue.new(Consts.ROLE_API, "apply_safe_mode").execute()
	DiffusionServer.generate(self, "_on_image_generated")


func _on_image_generated(result):
	var images_data = []
	
	# Images extraction
	#images_data = DiffusionServer.api.get_images_from_result(result, false, positive_prompt.text)
	if OS.has_feature("standalone"):
		images_data = DiffusionServer.api.get_images_from_result(result, false, positive_prompt.text)
	else:
		images_data = DiffusionServer.api.get_images_from_result(result, true, positive_prompt.text)
	
	# Seed extraction
	last_seed = DiffusionServer.api.get_seed_from_result(result)
	
	# Setting up the result images in the UI
	var cue = Cue.new(Consts.ROLE_TOOLBOX, "add_recent_data_images").args(images_data)
	var recent_thumbnail: RecentThumbnail = cue.execute()
	if recent_thumbnail.images_data.empty():
		recent_thumbnail.queue_free()
	else:
		recent_thumbnail.set_up_relay()
		Cue.new(Consts.ROLE_CANVAS, "set_images_in_generation_area"
			).args(
				images_data
			).opts({
				'relay': recent_thumbnail.image_viewer_relay,
				'focus': true
			}).execute()
	Cue.new(Consts.ROLE_ACTIVE_MODIFIER, "deselect").execute(false)
	Cue.new(Consts.ROLE_CANVAS, "open_board").execute()
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
			Consts.HELP_DESC_IMAGE_GENERATED]).execute()
	
	DiffusionServer.mark_generation_available()
	Tutorials.run_with_name(Tutorials.TUT2, true, [Tutorials.TUT1])


func add_prompt_and_seed_to_api(_cue: Cue = null):
	var config: Dictionary = {
		Consts.I_PROMPT: positive_prompt.text,
		Consts.I_NEGATIVE_PROMPT: negative_prompt.text,
	}
	var dict: Dictionary = {
		Consts.I_SEED: int(seed_field.text),
	}
	
	Cue.new(Consts.ROLE_API, "cue_apply_parameters").opts(dict).execute()
	Cue.new(Consts.ROLE_API, "cue_add_to_prompt").opts(config).execute()


func write_prompt(cue: Cue):
	# [positive_prompt, negative_prompt]
	var pos_prompt = cue.get_at(0, '')
	var neg_prompt = cue.get_at(1, '', false)
	if pos_prompt is String and positive_prompt.text.strip_edges().empty():
		positive_prompt.text = pos_prompt
		positive_prompt.label.visible = false
		positive_prompt.update_text()
	if neg_prompt is String and negative_prompt.text.strip_edges().empty():
		negative_prompt.text = neg_prompt
		negative_prompt.label.visible = false
		negative_prompt.update_text()



func _on_Seed_resized():
	if reuse_seed_button == null:
		return
	if rand_seed_button == null:
		return
	
	reuse_seed_button.rect_min_size.x = seed_field.rect_size.y
	rand_seed_button.rect_min_size.x = seed_field.rect_size.y


func _on_Random_pressed():
	seed_field.text = str(-1)


func _on_Reuse_pressed():
	seed_field.text = str(last_seed)


func _on_PositiveDropArea_modifier_dropped(_position, modifier: Modifier):
	if modifier.mode_name == "Styling":
		var styling_data = modifier.mode.get("styling_data")
		if styling_data is StylingData:
			_append_styling_data(styling_data, false)
	
	positive_prompt.update_text()
	negative_prompt.update_text()


func _on_NegativeDropArea_modifier_dropped(_position, modifier: Modifier):
	if modifier.mode_name == "Styling":
		var styling_data = modifier.mode.get("styling_data")
		if styling_data is StylingData:
			_append_styling_data(styling_data, true)
	
	positive_prompt.update_text()
	negative_prompt.update_text()


func _append_styling_data(styling_data: StylingData, is_negative: bool):
	if styling_data.is_negative:
		# Internally, styling_data.is_negative already switches the prompts by itself
		# thus a negative styling data will always be treated as negative regardless
		# of where it is dropped.
		# This behaviour could be changed upon users request
		is_negative = false
	
	var add_pos_prompt
	var add_neg_prompt
	if is_negative:
		add_pos_prompt = styling_data.get_negative_prompt()
		add_neg_prompt = styling_data.get_positive_prompt()
	else:
		add_pos_prompt = styling_data.get_positive_prompt()
		add_neg_prompt = styling_data.get_negative_prompt()
	
	
	if not add_pos_prompt.strip_edges().empty():
		if not positive_prompt.text.strip_edges().empty():
			positive_prompt.text += ", "
		
		positive_prompt.text += add_pos_prompt
	
	if not add_neg_prompt.strip_edges().empty():
		if not negative_prompt.text.strip_edges().empty():
			negative_prompt.text += ", "
		
		negative_prompt.text += add_neg_prompt


func _save_cues(_is_file_save):
	var config: Dictionary = {
		Consts.I_PROMPT: positive_prompt.text,
		Consts.I_NEGATIVE_PROMPT: negative_prompt.text,
		Consts.I_SEED: int(seed_field.text),
		PREV_SEED: last_seed,
	}
	Director.add_save_cue(
			Consts.SAVE, 
			Consts.ROLE_PROMPTING_AREA, 
			"load_prompt_and_seed", 
			[], 
			config)


func load_prompt_and_seed(cue: Cue):
	positive_prompt.text = cue.get_option(Consts.I_PROMPT, '')
	positive_prompt.update_text()
	negative_prompt.text = cue.get_option(Consts.I_NEGATIVE_PROMPT, '')
	negative_prompt.update_text()
	seed_field.text = str(cue.get_option(Consts.I_SEED, -1))
	last_seed = cue.get_option(PREV_SEED, -1)
