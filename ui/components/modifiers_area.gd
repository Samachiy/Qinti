extends Manager

const MODIFIER_NODE = preload("res://ui/modifiers/modifier.tscn")
const SCRIBBLE_DEFAULT_IMAGE_PATH = "res://assets/blank.png"
const DELETED_MODIFIERS_QUEUE_SIZE = 5

onready var modifier_container = $PanelContainer/ScrollContainer/Container
onready var load_img_button = $HBoxContainer/LoadImage
onready var add_button = $HBoxContainer/Add
onready var delete_button = $HBoxContainer/Delete
onready var other_button = $HBoxContainer/Other
onready var add_menu = $HBoxContainer/Add/Menu
onready var delete_menu = $HBoxContainer/Delete/Menu
onready var other_menu = $HBoxContainer/Other/Menu

var deleted_modifiers: Array = []
var scribble_defaul_image_data: ImageData = null
var scribble_defaul_image_obj: Texture
var update_order_on_child_exit: bool = true

func _ready():
	scribble_defaul_image_obj = load(ProjectSettings.globalize_path(SCRIBBLE_DEFAULT_IMAGE_PATH))
	var error = get_tree().connect("files_dropped", self, "_on_files_dropped")
	l.error(error, l.CONNECTION_FAILED)
	var type = Consts.LABEL_FONT_COLOR_A
	var group_name = Consts.THEME_MODULATE_GROUP_TYPE
	load_img_button.modulate.a8 = type
	Roles.request_role(self, Consts.ROLE_MODIFIERS_AREA)
	UIOrganizer.add_to_theme_by_modulate_group(load_img_button, group_name)
	add_button.modulate.a8 = type
	UIOrganizer.add_to_theme_by_modulate_group(add_button, group_name)
	delete_button.modulate.a8 = type
	UIOrganizer.add_to_theme_by_modulate_group(delete_button, group_name)
	other_button.modulate.a8 = type
	UIOrganizer.add_to_theme_by_modulate_group(other_button, group_name)
	scribble_defaul_image_data = ImageData.new("scribble_default")
	scribble_defaul_image_data.load_texture(scribble_defaul_image_obj)
	Tutorials.subscribe(self, Tutorials.TUT4)
	Tutorials.subscribe(self, Tutorials.TUT8)
	
	var ds = DiffusionServer
	ds.connect_feature(ds.FEATURE_CONTROLNET, self, "_on_controlnet_feature_toggled")


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUT4:
			var mod: Modifier = null
			for modifier in modifier_container.get_children():
				if modifier is Modifier:
					mod = modifier
					break
			
			if mod == null:
				return
			
			var board = Cue.new(Consts.ROLE_GENERATION_INTERFACE, "get_open_board").execute()
			if board == null:
				return
			
			
			tutorial_seq.add_tr_named_step(Tutorials.TUT4_CHANGE_MODIFIER, [mod.option_button])
			tutorial_seq.add_tr_named_step(Tutorials.TUT4_MODIFIER_HELP, [board.tutorial_button])
		Tutorials.TUT8:
			tutorial_seq.add_tr_named_step(Tutorials.TUT8_LOAD, [load_img_button])


func _on_controlnet_feature_toggled(enabled: bool):
	add_button.visible = enabled


func de_highlight_modifiers(_cue: Cue = null):
	for modifier in modifier_container.get_children():
		if modifier is Modifier:
			modifier.de_highlight()


func apply_modifiers_to_api():
	var modifier
	for i in range(modifier_container.get_child_count() - 1, -1, -1):
		modifier = modifier_container.get_child(i)
		modifier.apply_modifier_in_api(DiffusionServer.api)


func add_image_modifier(image: ImageData):
	var new_modifier = MODIFIER_NODE.instance()
	modifier_container.add_child(new_modifier)
	new_modifier.set_as_image_type(image)
	modifier_container.place_modifiers()


func add_scribble_modifier():
	var new_modifier = MODIFIER_NODE.instance()
	modifier_container.add_child(new_modifier)
	new_modifier.set_as_scribble_type(scribble_defaul_image_data)
	modifier_container.place_modifiers()


func add_regional_prompting_modifier():
	var new_modifier = MODIFIER_NODE.instance()
	modifier_container.add_child(new_modifier)
	new_modifier.set_as_regional_prompting_type(scribble_defaul_image_data)
	modifier_container.place_modifiers()


func update_canvas_overlay_underlay(cue: Cue):
	# [canvas: Control, target_mode: String, limiter: Modifier, 
	# overlay_underlay_material: Material]
	# The limiter wil divide between underlay and overlay when found
	var canvas = cue.get_at(0, null)
	var target_mode = cue.str_at(1, '')
	var limiter = cue.get_at(2, null)
	var overlay_underlay_material = cue.get_at(3, null, false)
	if canvas == null or target_mode.empty() or limiter == null:
		return
	
	var is_underlay = true
	canvas.lay.clear(canvas.MODIFIERS_OVERLAY)
	canvas.lay.clear(canvas.MODIFIERS_UNDERLAY)
	var is_target_modifier = false
	var modifier
	for i in range(modifier_container.get_child_count() - 1, -1, -1):
		modifier = modifier_container.get_child(i)
		if modifier == limiter:
			is_underlay = false
			continue
		
		is_target_modifier = modifier is Modifier and modifier.mode_name == target_mode
		if not is_target_modifier:
			continue
		
		if not modifier.is_active():
			continue
		
		var image = modifier.get_active_image()
		if is_underlay:
			canvas.lay.append(canvas.MODIFIERS_UNDERLAY, image)
		else:
			canvas.lay.append(canvas.MODIFIERS_OVERLAY, image)
	
	canvas.lay.refresh(canvas.MODIFIERS_UNDERLAY, overlay_underlay_material)
	canvas.lay.refresh(canvas.MODIFIERS_OVERLAY, overlay_underlay_material)


func _on_file_picker_files_selected(paths: PoolStringArray):
	for path in paths:
		if path is String:
			_on_file_picker_file_selected(path)


func _on_file_picker_file_selected(path: String):
	var image: ImageData = ImageData.new(path.get_file().get_basename())
	image.load_image_path(path)
	add_image_modifier(image)


func _on_LoadImage_pressed():
	var cue = Cue.new(Consts.ROLE_FILE_PICKER, "request_dialog")
	cue.args([self, "_on_file_picker_files_selected", FileDialog.MODE_OPEN_FILES])
	cue.execute()


func _on_DropArea_modifier_dropped(_position, modifier: Modifier):
	if modifier == null: 
		return
	
	_insert_modifier(modifier, modifier_container.empty_space_index)


func _insert_modifier(modifier: Modifier, index: int):
	modifier.reparent(modifier_container, index)
	modifier.visible = true
	modifier.is_in_modifier_area = true
	modifier.is_in_delete_area = false
	if modifier.mode is ModifierMode:
		modifier.mode.prepare_mode()
#		if DiffusionServer.features.has_feature(DiffusionServer.FEATURE_IMAGE_INFO):
#			modifier.mode.prepare_mode()
#		else:
#			modifier.reload_options("Img2Img") # selecting a mode will automatically prepare the mode
	modifier_container.place_modifiers()
	

func _on_DropArea_modifier_drop_attempted(position: Vector2, drop_area: DropArea):
	position -= modifier_container.rect_position
	var old_space_index = modifier_container.empty_space_index
	modifier_container.calculate_empty_space_index(position)
	if old_space_index != modifier_container.empty_space_index:
		modifier_container.place_modifiers()
	drop_area.connect_on_attempt_finished(self, "_on_DropArea_modifier_drop_attempt_finished")


func _on_DropArea_modifier_drop_attempt_finished():
	modifier_container.empty_space_index = -1
	modifier_container.place_modifiers()


func _on_Add_pressed():
	add_menu.clear()
	if DiffusionServer.features.has_feature(DiffusionServer.FEATURE_CONTROLNET):
		add_menu.add_tr_labeled_item(Consts.MENU_ADD_SCRIBBLE)
	add_menu.popup_at_cursor()


func _on_Delete_pressed():
	delete_menu.clear()
	delete_menu.add_tr_labeled_item(
			Consts.MENU_DELETE_ALL_MODIFIERS, 
			has_modifiers())
	delete_menu.add_tr_labeled_item(
			Consts.MENU_DELETE_SELECTED_MODIFIERS, 
			has_selected_modifiers())
	delete_menu.add_tr_labeled_item(
			Consts.MENU_DELETE_ACTIVE_MODIFIERS, 
			has_active_modifiers())
	delete_menu.add_tr_labeled_item(
			Consts.MENU_DELETE_INACTIVE_MODIFIERS, 
			has_inactive_modifiers())
	delete_menu.add_separator()
	delete_menu.add_tr_labeled_item(
			Consts.MENU_RESTORE_DELETED_MODIFIERS, 
			has_deleted_modifiers())
	delete_menu.popup_at_cursor()


func _on_Other_pressed():
	other_menu.clear()
	other_menu.add_tr_labeled_item(Consts.MENU_ACTIVATE_ALL_MODIFIERS)
	other_menu.add_tr_labeled_item(Consts.MENU_INACTIVATE_ALL_MODIFIERS)
	other_menu.popup_at_cursor()


func _on_Menu_option_selected(label_id, _index_id):
	match label_id:
		Consts.MENU_ADD_SCRIBBLE:
			add_scribble_modifier()
		Consts.MENU_DELETE_ALL_MODIFIERS:
			delete_all_modifiers()
		Consts.MENU_DELETE_SELECTED_MODIFIERS:
			delete_selected_modifiers()
		Consts.MENU_DELETE_ACTIVE_MODIFIERS:
			delete_active_modifiers()
		Consts.MENU_DELETE_INACTIVE_MODIFIERS:
			delete_inactive_modifiers()
		Consts.MENU_RESTORE_DELETED_MODIFIERS:
			restore_last_deleted_modifiers()
		Consts.MENU_ACTIVATE_ALL_MODIFIERS:
			set_all_modifiers_active_status(true)
		Consts.MENU_INACTIVATE_ALL_MODIFIERS:
			set_all_modifiers_active_status(false)


func has_modifiers():
	var success = false
	for modifier in modifier_container.get_children():
		if modifier is Modifier:
			success = true
			break
	
	return success


func has_selected_modifiers():
	var success = false
	for modifier in modifier_container.get_children():
		if modifier is Modifier and modifier.highlighted:
			success = true
			break
	
	return success


func has_active_modifiers():
	var success = false
	for modifier in modifier_container.get_children():
		if modifier is Modifier and modifier.is_active():
			success = true
			break
	
	return success


func has_inactive_modifiers():
	var success = false
	for modifier in modifier_container.get_children():
		if modifier is Modifier and not modifier.is_active():
			success = true
			break
	
	return success


func has_deleted_modifiers():
	return not deleted_modifiers.empty()


func delete_all_modifiers():
	var array = []
	for modifier in modifier_container.get_children():
		if modifier is Modifier:
			modifier.delete(array) # modifier is added to array inside delete()
	
	_add_modifiers_pending_for_delete(array)


func delete_selected_modifiers():
	var array = []
	for modifier in modifier_container.get_children():
		if modifier is Modifier and modifier.highlighted:
			modifier.delete(array) # modifier is added to array inside delete()
	
	_add_modifiers_pending_for_delete(array)


func delete_active_modifiers():
	var array = []
	for modifier in modifier_container.get_children():
		if modifier is Modifier and modifier.is_active():
			modifier.delete(array) # modifier is added to array inside delete()
	
	_add_modifiers_pending_for_delete(array)


func delete_inactive_modifiers():
	var array = []
	for modifier in modifier_container.get_children():
		if modifier is Modifier and not modifier.is_active():
			modifier.delete(array) # modifier is added to array inside delete()
	
	_add_modifiers_pending_for_delete(array)


func _add_modifiers_pending_for_delete(modifiers_array: Array):
	var mod_to_destroy: Array
	if deleted_modifiers.size() >= DELETED_MODIFIERS_QUEUE_SIZE:
		mod_to_destroy = deleted_modifiers.pop_front()
		if mod_to_destroy is Array:
			_destroy_modifiers(mod_to_destroy)
	
	deleted_modifiers.append(modifiers_array)


func cue_modifiers_pending_for_delete(cue: Cue):
	# [ modifier1, modifier2, ... ]
	var modifiers_array = []
	for arg in cue._arguments:
		if arg is Modifier:
			modifiers_array.append(arg)
	
	if not modifiers_array.empty():
		_add_modifiers_pending_for_delete(modifiers_array)


func _destroy_modifiers(modifiers_array: Array):
	for modifier in modifiers_array:
		if modifier is Modifier:
			modifier.destroy()


func restore_last_deleted_modifiers():
	var to_restore = deleted_modifiers.pop_back()
	for modifier in to_restore:
		if modifier is Modifier:
			_insert_modifier(modifier, -1) # -1 means append to last position


func set_all_modifiers_active_status(active: bool):
	for modifier in modifier_container.get_children():
		if modifier is Modifier:
			modifier.refresh_same_type = false
			modifier.set_active(active)
			modifier.refresh_same_type = true
	
	var active_mod = Roles.get_node_by_role(Consts.ROLE_ACTIVE_MODIFIER)
	if active_mod is Modifier:
		if active_mod.selected:
			active_mod.mode._on_same_type_modifier_toggled()


func _on_files_dropped(files: PoolStringArray, _screen: int):
	var image_data: ImageData = ImageData.new('')
	for file in files:
		if image_data.is_valid_image_type(file):
			image_data.load_image_path(file)
			image_data.set_name(file.get_file().get_basename())
			add_image_modifier(image_data)
			image_data = ImageData.new('')


func _on_Container_child_entered_tree(node: Node):
	if node is Modifier:
		var e = node.connect("tree_exited", self, "_on_Container_child_exited_tree", [node])
		l.error(e, l.CONNECTION_FAILED)


func _on_Container_child_exited_tree(node: Node):
	if is_instance_valid(node):
		node.disconnect("tree_exited", self, "_on_Container_child_exited_tree")
	
	if update_order_on_child_exit:
		modifier_container.place_modifiers()
