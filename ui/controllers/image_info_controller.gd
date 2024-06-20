extends Controller

class_name ImageInfoController

#const POSITIVE_PROMPT = "Positive prompt:"
#const NEGATIVE_PROMPT = "Negative prompt:"
#const CONFIG_DETAILS = "Steps:"
const SIZE_CONFIG_DISPLAY_NAME = "PNG_INFO_SIZE"
const MODEL_CONFIG_DISPLAY_NAME = "PNG_INFO_MODEL"
const OTHER_DETAILS_KEY = "PNG_INFO_OTHER"

onready var details_container = $HBoxContainer/ScrollContainer/Details
onready var details_scroll_container = $HBoxContainer/ScrollContainer
onready var prompt_mode_selector = $"%PromptMode"
onready var detail_info = $"%DetailInfo"
onready var menu_other = $"%Menu"
onready var menu_try = $"%TryMenu"

var detail_button = preload("res://ui/controllers/image_info_detail.tscn")
var image_data: ImageData = null
var formatted_info = null
#var raw_info = null
## This enum must be the same as the one in the modifier
#enum {
#	REPLACE,
#	APPEND,
#}


func _ready():
	prompt_mode_selector.add_tr_labeled_item(Consts.IMG_INFO_PROMPT_MODE_APPEND_PROMPT)
	prompt_mode_selector.add_tr_labeled_item(Consts.IMG_INFO_PROMPT_MODE_REPLACE_PROMPT)
	prompt_mode_selector.select_flag_value()
	
	menu_try.add_tr_labeled_item(Consts.TRY_PNG_INFO_IMAGE_ALL)
	menu_try.add_tr_labeled_item(Consts.TRY_PNG_INFO_IMAGE_CHECKED)
	menu_other.add_tr_labeled_item(Consts.COPY_CONFIG_DATA_RAW_TEXT)
	menu_other.add_tr_labeled_item(Consts.COPY_CONFIG_DATA_JSON)
	Tutorials.subscribe(self, Tutorials.TUTM1)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM1:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DETAILS, 
					[details_scroll_container])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DESC_BOX, 
					[details_scroll_container, detail_info])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_COPY, [menu_other])



func set_image(cue: Cue):
	image_data = cue.get_at(0, null)
	if image_data == null:
		l.g("Couldn't set image in Image info controller")
		return
	
	canvas.set_image_data(image_data)


func list_info(info_dict: Dictionary):
	var detail
	var model_name = ''
	var model_hash = ''
	for key in info_dict.keys():
		match key:
			SIZE_CONFIG_DISPLAY_NAME:
				detail = add_detail()
				detail.set_as_size_detail(
						SIZE_CONFIG_DISPLAY_NAME,
						info_dict[SIZE_CONFIG_DISPLAY_NAME]
						)
			Consts.SDO_ENSD, Consts.SDO_CLIP_SKIP:
				detail = add_detail()
				detail.set_as_setting_detail(key, info_dict[key])
			Consts.SDO_MODEL:
				model_name = info_dict[key]
			Consts.SDO_MODEL_HASH:
				model_hash = info_dict[key]
			OTHER_DETAILS_KEY:
				pass # We are going to add this later in this function
			_:
				detail = add_detail()
				detail.set_as_generation_detail(key, info_dict[key])
	
	if not model_hash.empty() or not model_name.empty():
		detail = add_detail()
		detail.set_as_model_detail(MODEL_CONFIG_DISPLAY_NAME, model_name, model_hash)
	
	if info_dict.has(OTHER_DETAILS_KEY):
		detail = add_detail()
		detail.set_as_disabled_detail(OTHER_DETAILS_KEY, info_dict[OTHER_DETAILS_KEY])


func get_config(_cue: Cue = null):
	var config: Dictionary = {}
	for detail in details_container.get_children():
		detail.append_if_checked(config)
	
	return config


func get_all_config(_cue: Cue = null):
	var config: Dictionary = {}
	for detail in details_container.get_children():
		detail.append(config)
	
	return config
	


func get_data_cue(_cue: Cue = null):
	if formatted_info == null:
		return null
	
	var checkboxes_status: Dictionary = {}
	for detail in details_container.get_children():
		checkboxes_status[detail.config_key] = detail.is_selected()
	
	var cue = Cue.new(Consts.ROLE_CONTROL_PNG_INFO, 'set_data_cue')
	if formatted_info == null:
		return null
	else:
		return cue.args([
				formatted_info.duplicate(), 
				checkboxes_status, 
				prompt_mode_selector.get_selected(),
#				raw_info])
				])


func set_data_cue(cue: Cue):
	clear()
	formatted_info = cue.get_at(0, {}, false)
	var checkboxes_status = cue.get_at(1, {}, false)
	var prompt_mode = cue.get_at(2, 0, false)
#	raw_info = cue.get_at(2, null, false)
	list_info(formatted_info)
	prompt_mode_selector.select_by_label(prompt_mode)
	for detail in details_container.get_children():
		if detail.config_key in checkboxes_status:
			detail.set_selected(checkboxes_status[detail.config_key])


func add_detail() -> Control:
	var detail = detail_button.instance()
	details_container.add_child(detail)
	detail.connect_detail(self, "_on_Detail_pressed")
	return detail


func clear(_cue: Cue = null):
	for child in details_container.get_children():
		child.queue_free()
	
	detail_info.text = ''
	prompt_mode_selector.selected_id = 0
	formatted_info = null


func replicate(replace_all: bool = true):
	Cue.new(Consts.ROLE_API, "clear").execute()
	
	var config
	if replace_all:
		config = get_all_config()
		Cue.new(Consts.ROLE_API, "cue_replace_parameters").opts(config).execute()
	else:
		config = get_config()
		Cue.new(Consts.ROLE_PROMPTING_AREA, "add_prompt_and_seed_to_api").execute()
		Cue.new(Consts.ROLE_CANVAS, "apply_parameters_to_api").execute()
		Cue.new(Consts.ROLE_API, "cue_apply_parameters").opts(config).execute()
	
	var prompting_area = Roles.get_node_by_role(Consts.ROLE_PROMPTING_AREA)
	if prompting_area is Object:
		DiffusionServer.generate(prompting_area, "_on_image_generated")
	else:
		l.g("Can't replicate, there's a node with the role ROLE_PROMPTING_AREA")


func _on_Detail_pressed(info):
	detail_info.text = str(info)


func _on_SelectAll_pressed():
	for child in details_container.get_children():
		child.select()


func _on_DeselectAll_pressed():
	for child in details_container.get_children():
		child.deselect()


func _fill_menu():
	pass # There's nothing to fill


func _on_Other_pressed():
	menu_other.popup_at_cursor()


func _on_Try_pressed():
	menu_try.popup_at_cursor()


func _on_TryMenu_option_selected(label_id, _index_id):
	match label_id:
		Consts.TRY_PNG_INFO_IMAGE_ALL:
			replicate(true)
		Consts.TRY_PNG_INFO_IMAGE_CHECKED:
			replicate(false)


func _on_Menu_option_selected(label_id, _index_id):
	var success = false
	match label_id:
		Consts.COPY_CONFIG_DATA_JSON:
			OS.set_clipboard(to_json(get_all_config()))
		Consts.COPY_CONFIG_DATA_RAW_TEXT:
			OS.set_clipboard(str(formatted_info))
	
	if success:
		Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
				Consts.HELP_DESC_INFO_COPIED_CLIPBOARD]).execute()
