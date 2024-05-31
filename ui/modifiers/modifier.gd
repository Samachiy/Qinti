extends MarginContainer

class_name Modifier

const SELECTED_MODE_NAME = "selected"
const IMAGE_DATA = "image"
const IMAGE_NAME = "image_name"

onready var core_mode_of_image_type = $Modes/PNGInfo
onready var alt_mode_of_image_type = $Modes/Img2Img
onready var styling_type = $Modes/Styling
onready var scribble_type = $Modes/Scribble
onready var regional_prompting_type = null
onready var texture_rect = $TextureRect
onready var main_button = $VBoxContainer/HBoxContainer/TextureButton
onready var option_button = $VBoxContainer/Controls/SmartOptionButton
onready var use_indicator = $VBoxContainer/HBoxContainer/UseIndicator
onready var not_use_indicator = $VBoxContainer/HBoxContainer/NotUseIndicator
onready var active_checkbox = $VBoxContainer/Controls/Active
onready var types_container = $Modes
onready var editing_indicator = $TextureRect/EditingIndicator
onready var editing_icon = $TextureRect/EditingIcon
onready var highlight_indicator = $TextureRect/HighlightIndicator
onready var focus_indicator = $TextureRect/FocusIndicator # not in use
onready var hover_indicator = $TextureRect/HoverIndicator
onready var menu = $"%Menu"
onready var label = $"%ModifierName"
onready var label_bg = $"%ModifierNameBG"
onready var warning_icon = $"%WarningIcon"

var mode: Node = null
var image_data: ImageData = null
var is_in_modifier_area = true
var is_in_delete_area = false
var mode_name = ''
var pressed_right = false
var pressed_left = false
var refresh_same_type = true

# Warning, from code to ui, highlight -> select and select -> editing
# If selected is true, we are editing the modifier
# If highlight is true, we are selecting this (and maybe others too) to execute a batch action
var selected: bool = false
var highlighted: bool = false 


func _ready():
	editing_indicator.visible = false
	editing_icon.visible = false
	highlight_indicator.visible = false
	editing_icon.modulate.a8 = Consts.OPPOSITE_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(
			editing_icon, Consts.THEME_MODULATE_GROUP_STYLE)
	editing_indicator.modulate.a8 = Consts.MATCHING_GLASS_A
	UIOrganizer.add_to_theme_by_modulate_group(
			editing_indicator, Consts.THEME_MODULATE_GROUP_STYLE)
	use_indicator.modulate.a8 = Consts.ACCENT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(
			use_indicator, Consts.THEME_MODULATE_GROUP_STYLE)
	highlight_indicator.modulate.a8 = Consts.ACCENT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(
			highlight_indicator, Consts.THEME_MODULATE_GROUP_STYLE)
	
	menu.add_tr_labeled_item(Consts.MENU_DELETE)
	refresh_same_type = false
	set_active(active_checkbox.pressed)
	_on_Active_toggled(active_checkbox.pressed)
	refresh_same_type = true
	
	# Connecting features
	var  e = DiffusionServer.features.connect("features_changed", self, "_on_features_changed")
	l.error(e, l.CONNECTION_FAILED)
	#_refresh_features()


func apply_modifier_in_api(api: HTTPRequest):
	if is_active():
		mode.apply_to_api(api)


func set_as_image_type(image: ImageData):
	# set_in_combobox also loads the mode, since a mode is always loaded when selected
	# in the option_button. This will also load the image_data into the mode
	if DiffusionServer.features.has_feature(DiffusionServer.FEATURE_IMAGE_INFO):
		_refresh_image_data_with(image) # This must go first since we are loading the image
		core_mode_of_image_type.set_in_combobox(option_button, true)
	else:
		set_as_image_type_alt(image)


func set_as_image_type_alt(image: ImageData):
	# This sets the modifier as img2img rather than image_info, this is intended for stuff
	# that may not have info embedded in the image
	_refresh_image_data_with(image) # This must go first since we are loading the image
	
	if DiffusionServer.features.has_feature(DiffusionServer.FEATURE_IMG_TO_IMG):
		alt_mode_of_image_type.set_in_combobox(option_button, true)
	else:
		force_set_mode(alt_mode_of_image_type)


func set_as_style_type(styling_data: StylingData):
	# set_in_combobox also loads the mode, since a mode is always loaded when selected
	# in the option_button. This will also load the image_data into the mode
	_refresh_image_data_with(styling_data.get_image_data()) # This must go first 
	styling_type.set_in_combobox(option_button, true)
	styling_type.styling_data = styling_data
	_refresh_label()


func set_as_scribble_type(image: ImageData):
	# set_in_combobox also loads the mode, since a mode is always loaded when selected
	# in the option_button. This will also load the image_data into the mode
	_refresh_image_data_with(image) # This must go first since we are loading the image
	scribble_type.set_in_combobox(option_button, true)


func set_as_regional_prompting_type(image: ImageData):
	# set_in_combobox also loads the mode, since a mode is always loaded when selected
	# in the option_button. This will also load the image_data into the mode
	if regional_prompting_type == null:
		return
	_refresh_image_data_with(image) # This must go first since we are loading the image
	regional_prompting_type.set_in_combobox(option_button, true)


func _refresh_image_data_with(new_image_data: ImageData):
	image_data = new_image_data
	texture_rect.texture = image_data.texture
	_refresh_label()


func _refresh_label():
	if mode == null: 
		label.visible = false
		return
	
	if mode.name == "Styling":
		label_bg.modulate.a8 = Consts.LABEL_FONT_COLOR_INVERSE_A
		UIOrganizer.add_to_theme_by_modulate_group(label_bg, Consts.THEME_MODULATE_GROUP_TYPE)
		if not label.is_connected("resized", self, "_on_Label_resized"):
			label.connect("resized", self, "_on_Label_resized")
		label.visible = true
		label.text = mode.styling_data.file_cluster.name
		_on_Label_resized()
	else:
		label.visible = false


func reparent(new_parent: Node, index: int = -1):
	if new_parent == null:
		return
	
	_remove_from_parent()
	new_parent.add_child(self)
	if index >= 0:
		new_parent.move_child(self, index)


func _remove_from_parent():
	var old_parent = get_parent()
	if old_parent != null:
		old_parent.remove_child(self)


func deselect(_cue: Cue = null):
	# Warning, from code to ui, highlight -> select and select -> editing
	# thus this exits edit mode
	selected = false
	editing_indicator.visible = false
	editing_icon.visible = false
	if mode != null:
		mode.deselect_mode()


func select(): 
	# Warning, from code to ui, highlight -> select and select -> editing
	# thus this enters edit mode
	Tutorials.run_with_name(Tutorials.TUT4, true, [Tutorials.TUT1, Tutorials.TUT2])
	editing_indicator.visible = true
	editing_icon.visible = true
	if mode != null:
		if selected:
			mode.select_mode()
		else:
			deselect_active_modifier()
			selected = true
			mode.clear_board()
			mode.select_mode()
			Roles.request_role(self, Consts.ROLE_ACTIVE_MODIFIER, true)
	else:
		deselect()


func highlight():
	# Warning, from code to ui, highlight -> select and select -> editing
	# thus this selects the modifier (as, for example, to delete it)
	highlight_indicator.visible = true
	highlighted = true


func de_highlight():
	# Warning, from code to ui, highlight -> select and select -> editing
	# thus this deselects the modifier (as, for example, to not delete it)
	highlight_indicator.visible = false
	highlighted = false


func deselect_active_modifier():
	# Warning, from code to ui, highlight -> select and select -> editing
	# thus this exits edit mode
	if Roles.has_role(Consts.ROLE_ACTIVE_MODIFIER):
		var active_modifier = Roles.get_node_by_role(Consts.ROLE_ACTIVE_MODIFIER)
		if active_modifier != self:
			Cue.new(Consts.ROLE_ACTIVE_MODIFIER, "deselect").execute()


func delete(deleted_queue: Array):
	# The deleted queue is there so that there is a possibility for the delete to be undone
	if selected:
		deselect()
		Roles.delete_role(Consts.ROLE_ACTIVE_MODIFIER)
		Cue.new(Consts.ROLE_GENERATION_INTERFACE, "show_main_board").execute()
	
	highlighted = false
	selected = false
	is_in_modifier_area = false
	is_in_delete_area = true
	visible = false
	_remove_from_parent()
	deleted_queue.append(self)


func destroy():
	# In contrast to delete, this is meant to be permanent
	# This function asumes that delete() was called before and thus no need to deselect
	if is_in_modifier_area:
		delete([])
		l.g("Modifier was destroyed before deleting or without never even been added, " + 
				"executing emergency delete. Program misbehaviour may happen. Metadata: " + 
				mode_name + "/ " + get_path())
	
	queue_free()


func is_active():
	return active_checkbox.pressed


func set_active(active: bool):
	active_checkbox.pressed = active


func _on_mode_loaded(new_mode):
	if new_mode == null:
		return
	
	var old_mode = mode
	mode = new_mode
	if new_mode.image_data == null:
		new_mode.set_image_data(image_data)
	
	if selected:
		if old_mode != null:
			old_mode.deselect_mode()
		
		new_mode.select_mode()
	elif is_in_modifier_area:
		new_mode.prepare_mode()
	
	mode_name = new_mode.name
	_refresh_features()


func _on_SmartOptionButton_option_selected(option_label, _id):
	var mode_node = types_container.get_node_or_null(option_label)
	if mode_node == null:
		l.g("The mode '" + option_label + "' is not on the type list.")
		return
	
	mode_node.load_mode()


func get_active_image() -> Image:
	if mode == null:
		return null
	
	var active_image = mode.get_active_image()
	if active_image is Image:
		return active_image
	else:
		return null



func _on_TextureButton_focus_entered():
#	focus_indicator.visible = true
	pass


func _on_TextureButton_focus_exited():
#	focus_indicator.visible = false
	pass


func _on_TextureButton_pressed():
	if Input.is_action_pressed("ui_ctrl"):
		if highlighted:
			de_highlight()
		else:
			highlight()
	elif is_in_modifier_area:
		select()
		Cue.new(Consts.ROLE_MODIFIERS_AREA, "de_highlight_modifiers").execute()


func _on_Active_toggled(button_pressed):
	use_indicator.visible = button_pressed
	not_use_indicator.visible = not use_indicator.visible
	if not refresh_same_type:
		return
	
	var active_mod = Roles.get_node_by_role(Consts.ROLE_ACTIVE_MODIFIER, false)
	if active_mod != null and active_mod.has_method("_on_Active_toggled"):
		if mode_name == active_mod.mode_name:
			active_mod.mode._on_same_type_modifier_toggled()


func _on_Menu_option_selected(label_id, _index_id):
	match label_id:
		Consts.MENU_DELETE:
			var array = []
			delete(array)
			Cue.new(
					Consts.ROLE_MODIFIERS_AREA, 
					"cue_modifiers_pending_for_delete"
				).args(array).execute()


func _on_TextureButton_gui_input(event):
	if not event is InputEventMouseButton:
		return
	
	# left click
	if event.get_button_index() == BUTTON_RIGHT:
		if pressed_right and not event.pressed:
			menu.popup_at_cursor()
		
		pressed_right = event.pressed
	
	# left click
	if event.get_button_index() == BUTTON_LEFT:
		if pressed_left and not event.pressed:
			_on_TextureButton_pressed()
		
		pressed_left = event.pressed


func _on_TextureButton_mouse_entered():
	hover_indicator.visible = true


func _on_TextureButton_mouse_exited():
	hover_indicator.visible = false


func _on_Label_resized():
	if not label.visible:
		return
	
	yield(get_tree(), "idle_frame")
	if label.rect_position.y < 0:
		label.rect_position.y = 0
		
	var is_default_image = image_data == Consts.default_image_data
	if is_default_image:
		label_bg.color.a8 = 170
		label.rect_position.y = 0
		label.rect_size.y = main_button.rect_size.y
		label.autowrap = true
		label.align = label.ALIGN_CENTER
		label.valign = label.VALIGN_CENTER
		label.clip_text = false
	else:
		label_bg.color.a8 = 170
		label.rect_size.y = 1
		label.autowrap = false
		label.align = label.ALIGN_LEFT
		label.valign = label.VALIGN_BOTTOM
		label.clip_text = true
		if label.rect_position.y <= 0:
			label.rect_size.y = 0
			yield(get_tree(), "idle_frame")
			label.rect_position.y = main_button.rect_size.y - label.rect_size.y


func _on_TextureButton_button_up():
	_on_TextureButton_pressed()


# FEATURES SIGNALS

func _refresh_features():
	warning_icon.hint_tooltip = ''
	warning_icon.visible = false
# warning-ignore:unused_variable
#	var feature_match: bool = false
#	feature_match = _on_controlnet_feature_toggled(ds.features.has_feature(ds.FEATURE_CONTROLNET))
	_on_features_changed()


func _on_features_changed():
	if mode == null:
		return false
	
	var result = reload_options()
	if result == 1:
		warning_icon.visible = false
	elif result == 0:
		warning_icon.visible = true
		warning_icon.hint_tooltip += tr(DiffusionServer.MSG_NO_FEATURE_GENERIC) + "\n"


func reload_options(select_label: String = ''):
	return mode.reload_combobox(option_button, select_label)


func force_set_mode(mode_to_set: Node):
	mode_to_set.reload_combobox(option_button, mode_to_set.name)
	_on_SmartOptionButton_option_selected(mode_to_set.name, -1)


func force_set_mode_label(mode_node_name: String):
	var mode_to_set = types_container.get_node_or_null(mode_node_name)
	if mode_to_set is ModifierMode:
		mode_to_set.reload_combobox(option_button, mode_node_name)
		_on_SmartOptionButton_option_selected(mode_node_name, -1)
	else:
		l.g("Modifier mode '" + mode_node_name + "' resulted in '" + str(mode_to_set) + 
				"'. Can't set mode.")


func get_modes_data():
	var data = {}
	for mode_node in types_container.get_children():
		if mode_node is ModifierMode and mode_node.loaded_once:
			data[mode_node.name] = mode_node.get_mode_data()
	
	data[SELECTED_MODE_NAME] = mode_name
	data[IMAGE_DATA] = image_data.get_base64()
	data[IMAGE_NAME] = image_data.image_name
	return data


func set_modes_data(data: Dictionary):
	var mode_node
	var default_mode: String = ''
	image_data = ImageData.new(data.get(IMAGE_NAME, ""))
	image_data.load_base64(data.get(IMAGE_DATA, ""))
	
	for mode_key in data:
		if default_mode.empty():
			default_mode = mode_key
		mode_node = types_container.get_node_or_null(mode_key)
		if mode_node is ModifierMode:
			mode_node.set_mode_data(data[mode_node.name])
	
	var select_mode = data.get(SELECTED_MODE_NAME, "")
	if select_mode.empty():
		select_mode = default_mode
	
	_refresh_image_data_with(image_data)
	force_set_mode_label(select_mode)
	_refresh_label()



func queue_hash_now():
	if styling_type.loaded_once:
		styling_type.queue_hash_now()




