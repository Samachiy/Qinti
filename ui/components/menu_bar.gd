extends Panel

onready var main_menu = $Menu/Buttons/Menu
onready var server_menu = $Menu/Buttons/Server
onready var settings_menu = $Menu/Buttons/Settings
onready var help_menu = $Menu/Buttons/Help
onready var dev_menu = $Menu/Buttons/Developer
onready var menu_container = $Menu
onready var theme_buttons = $DarkLightMode/Buttons/Themes/Buttons
onready var theme_container = $DarkLightMode/Buttons/Themes
onready var show_hide_theme_buttons = $DarkLightMode/Buttons/ShowHideThemes
onready var light_dark_theme_button = $DarkLightMode/Buttons/LightDarkMode
onready var theme_buttons_center = $DarkLightMode/Buttons/SpacingCenter

const THEME_AREA_ANIM_TIME = 0.5
const HIDE_SHOW_TIME = 0.2
const SHOW_THEMES_TEXT = "<"
const HIDE_THEMES_TEXT = "X"
const LIGHT_MODE_TEXT = "LIGHT_MODE"
const DARK_MODE_TEXT = "DARK_MODE"

const EXIT = "EXIT"
const SAVE_PROJECT = "SAVE_PROJECT"
const SAVE_PROJECT_AS = "SAVE_PROJECT_AS"
const SAVE_CANVAS_IMAGE = "SAVE_CANVAS_IMAGE"
const SAVE_CANVAS_IMAGE_AS = "SAVE_CANVAS_IMAGE_AS"
const LOAD_PROJECT = "LOAD_PROJECT"
const NEW = "NEW"
const RESTART_SERVER = "RESTART_SERVER"
const REINSTALL_OR_CHANGE_SERVER = "REINSTALL_OR_CHANGE_SERVER"
const HIDE_MENU = "HIDE_MENU"
const HIDE_DESCRIPTION_BAR = "HIDE_DESCRIPTION_BAR"
const CHANGE_THEME_COLOR = "CHANGE_THEME_COLOR"
const ADVANCED_GENERATION_OPTIONS = "ADVANCED_GENERATION_OPTIONS"
const ENABLE_TUTORIALS = "ENABLE_TUTORIALS"
const RESET_SEEN_TUTORIALS = "RESET_SEEN_TUTORIALS"
const SHOW_SERVER_STATE = "SHOW_SERVER_STATE"
const SHUTDOWN_SERVER = "SHUTDOWN_SERVER"
const SHOW_ABOUT = "SHOW_ABOUT"
const TUTORIALS = "TUTORIALS"
const LANGUAGES = "LANGUAGE"
const TUT5_LORA_LYCORIS_TI = "TUT5_LORA_LYCORIS_TI"
const TUT6_MODELS = "TUT6_MODELS"
const TUT7_LOG_AND_STATUS = "TUT7_LOG_AND_STATUS"
const TUT8_OPENING_SAVING_IMG = "TUT8_OPENING_SAVING_IMG"
const TUT9_INPAINTING = "TUT9_INPAINTING"
const TUT10_OUTPAINTING = "TUT10_OUTPAINTING"

const DEV_TOGGLE_CONTROLNET = "DEV_TOGGLE_CONTROLNET"
const DEV_TOGGLE_INOUTPAINT = "DEV_TOGGLE_INOUTPAINT"
const DEV_TOGGLE_IMG2IMG = "DEV_TOGGLE_IMG2IMG"
const DEV_TOGGLE_IMG_INFO = "DEV_TOGGLE_IMG_INFO"

var color_button_node = preload("res://ui/components/color_button.tscn")
var id_to_label: Dictionary = {}
var label_to_id: Dictionary = {}
var id_counter: int = 0
var checkboxes: Dictionary = {} # { label1: MenuCheckbox1, label2: MenuCheckbox2, ...}
var themes_area_tween: SceneTreeTween = null
var hide_show_tween: SceneTreeTween = null
var is_hiding: bool = false
var tutorials_menu = PopupMenu.new()
var languages_menu = PopupMenu.new()
var is_themes_showing: bool = false
var advanced_ui: bool = false

signal hiding_toggled(is_hiding_value)


func _ready():
	Roles.request_role(self, Consts.ROLE_MENU_BAR)
	show_hide_theme_buttons.text = SHOW_THEMES_TEXT
	var e = ThemeChanger.connect("theme_changed", self, "_on_theme_changed")
	l.error(e, l.CONNECTION_FAILED)
	var checkbox: MenuCheckbox
	# Connecting menus
	connect_menu_button(main_menu)
	connect_menu_button(server_menu)
	connect_menu_button(settings_menu)
	connect_menu_button(help_menu)
	connect_menu_button(tutorials_menu)
	# Adding items
	#add_tr_item_button(main_menu, NEW)
	add_tr_item_button(main_menu, SAVE_PROJECT, KEY_S + KEY_MASK_CTRL)
	add_tr_item_button(main_menu, SAVE_PROJECT_AS)
	add_separator(main_menu)
	add_tr_item_button(main_menu, SAVE_CANVAS_IMAGE)
	add_tr_item_button(main_menu, SAVE_CANVAS_IMAGE_AS)
	add_separator(main_menu)
	add_tr_item_button(main_menu, LOAD_PROJECT)
	add_separator(main_menu)
	add_tr_item_button(main_menu, EXIT)
	add_tr_item_button(server_menu, SHOW_SERVER_STATE)
	add_separator(server_menu)
	add_tr_item_button(server_menu, RESTART_SERVER)
	add_tr_item_button(server_menu, REINSTALL_OR_CHANGE_SERVER)
	add_tr_item_button(server_menu, SHUTDOWN_SERVER)
	checkbox = add_tr_item_checkbox(settings_menu, HIDE_MENU)
	checkbox.set_accelerator(KEY_H + KEY_MASK_CTRL)
	add_tr_item_checkbox(settings_menu, HIDE_DESCRIPTION_BAR)
	add_tr_item_button(settings_menu, CHANGE_THEME_COLOR)
	checkbox = add_tr_item_checkbox(settings_menu, ADVANCED_GENERATION_OPTIONS)
	checkbox.set_flag_name(ADVANCED_GENERATION_OPTIONS, self)
	set_advanced_mode(false)
	add_tr_item_submenu(help_menu, TUTORIALS, tutorials_menu)
	add_tr_item_button(tutorials_menu, TUT5_LORA_LYCORIS_TI)
	add_tr_item_button(tutorials_menu, TUT6_MODELS)
	add_tr_item_button(tutorials_menu, TUT7_LOG_AND_STATUS)
	add_tr_item_button(tutorials_menu, TUT8_OPENING_SAVING_IMG)
	add_tr_item_button(tutorials_menu, TUT9_INPAINTING)
	add_tr_item_button(tutorials_menu, TUT10_OUTPAINTING)
	add_tr_item_button(help_menu, RESET_SEEN_TUTORIALS)
	add_tr_item_button(help_menu, SHOW_ABOUT)
	
	# Adding languages
	add_tr_item_submenu(settings_menu, LANGUAGES, languages_menu)
	e = languages_menu.connect("id_pressed", self, "_on_language_option_selected")
	l.error(e, l.CONNECTION_FAILED)
	for language_str in Locale.available:
		if language_str is String:
			add_labeled_item_button(languages_menu, language_str.to_upper(), language_str)
	
	_on_theme_changed()
	Tutorials.subscribe(self, Tutorials.TUT1)
	Tutorials.subscribe(self, Tutorials.TUT4)
	Tutorials.subscribe(self, Tutorials.TUT7)
	Tutorials.subscribe(self, Tutorials.TUT9)
	Tutorials.subscribe(self, Tutorials.TUT10)
	Tutorials.subscribe(self, Tutorials.TUTM2)
	
	if not OS.has_feature("standalone"):
		connect_menu_button(dev_menu)
		add_tr_item_checkbox(dev_menu, DEV_TOGGLE_CONTROLNET)
		add_tr_item_checkbox(dev_menu, DEV_TOGGLE_INOUTPAINT)
		add_tr_item_checkbox(dev_menu, DEV_TOGGLE_IMG2IMG)
		add_tr_item_checkbox(dev_menu, DEV_TOGGLE_IMG_INFO)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUT1:
			tutorial_seq.add_tr_named_step(Tutorials.TUT1_ADVAN_PARAMETERS, [settings_menu])
		Tutorials.TUT4:
			tutorial_seq.add_tr_named_step(Tutorials.TUT4_TUTORIALS, [help_menu])
		Tutorials.TUT7:
			tutorial_seq.add_tr_named_step(Tutorials.TUT7_OPENING, [server_menu])
		Tutorials.TUT9:
			tutorial_seq.add_tr_named_step(Tutorials.TUT9_DENOISING, [settings_menu])
		Tutorials.TUT10:
			tutorial_seq.add_tr_named_step(Tutorials.TUT10_DENOISING, [settings_menu])
		Tutorials.TUTM2:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM2_EXTRA_TYPES, [settings_menu])


func get_popup_menu(menu) -> PopupMenu:
	if menu is MenuButton:
		return menu.get_popup()
	elif menu is PopupMenu:
		return menu
	else:
		l.g("The Control passed to MenuBar is not a menu. Menu: " + str(menu))
		return null
	


func connect_menu_button(menu):
	var popup = get_popup_menu(menu)
	var e = popup.connect("id_pressed", self, "_on_menu_option_selected")
	l.error(e, l.CONNECTION_FAILED)


func add_separator(menu, label: String = ''):
	var popup = get_popup_menu(menu)
	popup.add_separator(label, id_counter)
	id_counter += 1


func add_tr_item_button(menu, label: String, accelerator: int = -1):
	if _has_id_label_conflicts(id_counter, label):
		return
	
	var popup = get_popup_menu(menu)
	popup.add_item(label, id_counter)
	id_to_label[id_counter] = label
	label_to_id[label] = id_counter
	if accelerator != -1:
		popup.set_item_accelerator(id_counter, accelerator)
	
	id_counter += 1


func add_labeled_item_button(menu, text: String, label: String):
	if _has_id_label_conflicts(id_counter, label):
		return
	
	var popup = get_popup_menu(menu)
	popup.add_item(text, id_counter)
	id_to_label[id_counter] = label
	label_to_id[label] = id_counter
	id_counter += 1


func add_tr_item_submenu(menu_button: MenuButton, label: String, submenu: PopupMenu):
	if _has_id_label_conflicts(id_counter, label):
		return
	
	var popup = get_popup_menu(menu_button)
	popup.add_child(submenu)
	submenu.set_name(label)
	popup.add_submenu_item(label, submenu.name, id_counter)
	id_to_label[id_counter] = label
	label_to_id[label] = id_counter
	id_counter += 1


func add_tr_item_checkbox(menu, label: String):
	if _has_id_label_conflicts(id_counter, label):
		return
	
	var popup = get_popup_menu(menu)
	var index = popup.get_item_count()
	var menu_checkbox = MenuCheckbox.new(popup, id_counter, index)
	popup.add_check_item(label, id_counter)
	checkboxes[label] = menu_checkbox
	id_to_label[id_counter] = label
	label_to_id[label] = id_counter
	id_counter += 1
	return menu_checkbox


func add_color_theme_button(theme_data: ThemeData):
	var new_button = color_button_node.instance()
	new_button.set_theme_data(theme_data)
	theme_buttons.add_child(new_button)
	new_button.connect("theme_selected", self, "_on_ColorButton_pressed")


func _has_id_label_conflicts(id: int, label: String):
	var has_conflicts = false
	if label.empty():
		has_conflicts = true
		l.g("There was an error setting item, label is empty. No item was created.")
	elif id_to_label.has(id):
		has_conflicts = true
		l.g("There was an error setting item '" + label + 
				"', id number already exists. No item was created.")
	elif label_to_id.has(label):
		has_conflicts = true
		l.g("There was an error setting item '" + label + 
				"', label already exists. No item was created.")
	
	return has_conflicts


func is_checkbox_pressed(label: String):
	var checkbox = checkboxes.get(label)
	if checkbox is MenuCheckbox:
		return checkbox.is_pressed()
	else:
		return false


func set_checkbox_pressed(label: String, pressed: bool):
	var checkbox = checkboxes.get(label)
	if checkbox is MenuCheckbox:
		if pressed:
			checkbox.check()
		else:
			checkbox.uncheck()


func hide():
	if hide_show_tween is SceneTreeTween:
		hide_show_tween.kill()
	
	is_hiding = true
	var distance = rect_size.y + rect_position.y
	var time = HIDE_SHOW_TIME * distance / rect_min_size.y
	hide_show_tween = create_tween().bind_node(self)
	var error = hide_show_tween.connect("finished", self, "_on_hide_show_finished")
	l.error(error, l.CONNECTION_FAILED)
# warning-ignore:return_value_discarded
	hide_show_tween.tween_property(self, "rect_position:y", -rect_size.y, time).from_current()


func show():
	if hide_show_tween is SceneTreeTween:
		hide_show_tween.kill()
	
	is_hiding = false
	var distance = abs(rect_position.y)
	var time = HIDE_SHOW_TIME * distance / rect_min_size.y
	hide_show_tween = create_tween().bind_node(self)
	var error = hide_show_tween.connect("finished", self, "_on_hide_show_finished")
	l.error(error, l.CONNECTION_FAILED)
# warning-ignore:return_value_discarded
	hide_show_tween.tween_property(self, "rect_position:y", 0, time).from_current()


func _on_hide_show_finished():
	emit_signal("hiding_toggled", is_hiding)


func show_themes_colors():
	UIOrganizer.hide_show_node(menu_container, theme_buttons, 0.1, 0.1)
	show_hide_theme_buttons.text = HIDE_THEMES_TEXT


func hide_themes_colors():
	UIOrganizer.hide_show_node(theme_buttons, menu_container, 0.1, 0.1)
	show_hide_theme_buttons.text = SHOW_THEMES_TEXT


func _on_ShowHideThemes_pressed():
	match show_hide_theme_buttons.text:
		SHOW_THEMES_TEXT:
			show_themes_colors()
		HIDE_THEMES_TEXT:
			hide_themes_colors()


func _on_LightDarkMode_pressed():
	ThemeChanger.toggle_light_dark_theme()


func _on_theme_changed():
	var is_dark = ThemeChanger.current_theme.is_dark
	if is_dark:
		light_dark_theme_button.text = LIGHT_MODE_TEXT
	else:
		light_dark_theme_button.text = DARK_MODE_TEXT
	
	for theme_button in theme_buttons.get_children():
		if theme_button is Control:
			theme_button.queue_free()
	# Adding themes
	for theme_data in ThemeChanger.data.values():
		if theme_data is ThemeData and theme_data.is_dark == is_dark:
			add_color_theme_button(theme_data)


func _on_ColorButton_pressed(theme_data: ThemeData):
	ThemeChanger.load_theme_data(theme_data)


func _on_language_option_selected(id: int):
	var label: String = id_to_label.get(id, '')
	if label.empty():
		return
	
	UIOrganizer.set_locale(label)


func set_advanced_mode(value: bool):
	advanced_ui = value
	for node in get_tree().get_nodes_in_group(Consts.UI_MINIMALIST_GROUP):
		if node is CanvasItem:
			node.visible = not value
	for node in get_tree().get_nodes_in_group(Consts.UI_ADVANCED_GROUP):
		if node is CanvasItem:
			node.visible = value


func _on_menu_option_selected(id: int):
	var label: String = id_to_label.get(id, '')
	if label.empty():
		return
	
	match label:
		EXIT:
			exit()
		SAVE_PROJECT:
			Cue.new(Consts.ROLE_GENERATION_INTERFACE, "save_as").args([true]).execute()
		SAVE_PROJECT_AS:
			Cue.new(Consts.ROLE_GENERATION_INTERFACE, "save_as").args([false]).execute()
		LOAD_PROJECT:
			Cue.new(Consts.ROLE_GENERATION_INTERFACE, "load_from").execute()
		SAVE_CANVAS_IMAGE:
			Cue.new(Consts.ROLE_ACTIVE_MODIFIER, "deselect").execute(false)
			Cue.new(Consts.ROLE_CANVAS, "open_board").execute()
			yield(get_tree(), "idle_frame")
			Cue.new(Consts.ROLE_CANVAS, "cue_menu_option").args(
					[Consts.MENU_SAVE_CANVAS]).execute()
		SAVE_CANVAS_IMAGE_AS:
			Cue.new(Consts.ROLE_ACTIVE_MODIFIER, "deselect").execute(false)
			Cue.new(Consts.ROLE_CANVAS, "open_board").execute()
			yield(get_tree(), "idle_frame")
			Cue.new(Consts.ROLE_CANVAS, "cue_menu_option").args([
					Consts.MENU_SAVE_CANVAS_AS]).execute()
		LOAD_PROJECT:
			Cue.new(Consts.ROLE_GENERATION_INTERFACE, "load_from").args([false]).execute()
		NEW:
			Director.reload_current_scene(true)
		RESTART_SERVER:
			DiffusionServer.server.restart_server()
		REINSTALL_OR_CHANGE_SERVER:
			Cue.new(Consts.ROLE_SERVER_MANAGER, "show_installation_window").args([false]).execute()
		HIDE_MENU:
			if is_hiding:
				show()
			else:
				hide()
		HIDE_DESCRIPTION_BAR:
			if is_checkbox_pressed(label):
				set_checkbox_pressed(label, false)
				Cue.new(Consts.ROLE_DESCRIPTION_BAR, "show").execute()
			else:
				set_checkbox_pressed(label, true)
				Cue.new(Consts.ROLE_DESCRIPTION_BAR, "hide").execute()
		CHANGE_THEME_COLOR:
			show_themes_colors()
		ADVANCED_GENERATION_OPTIONS:
			if is_checkbox_pressed(label):
				set_checkbox_pressed(label, false)
				set_advanced_mode(false)
			else:
				set_checkbox_pressed(label, true)
				set_advanced_mode(true)
		ENABLE_TUTORIALS:
			Tutorials.is_enabled = is_checkbox_pressed(label)
		RESET_SEEN_TUTORIALS:
			Tutorials.reset()
		SHOW_SERVER_STATE:
			Cue.new(Consts.ROLE_SERVER_STATE_INDICATOR, "show").execute()
		SHUTDOWN_SERVER:
			DiffusionServer.server.stop_server()
		SHOW_ABOUT:
			Cue.new(Consts.ROLE_ABOUT_WINDOW, "open").execute()
		TUT5_LORA_LYCORIS_TI:
			Tutorials.run_with_name(Tutorials.TUT5, false)
		TUT6_MODELS:
			Tutorials.run_with_name(Tutorials.TUT6, false)
		TUT7_LOG_AND_STATUS:
			Tutorials.run_with_name(Tutorials.TUT7, false)
		TUT8_OPENING_SAVING_IMG:
			Tutorials.run_with_name(Tutorials.TUT8, false)
		TUT9_INPAINTING:
			Tutorials.run_with_name(Tutorials.TUT9, false)
		TUT10_OUTPAINTING:
			Tutorials.run_with_name(Tutorials.TUT10, false)
		
		DEV_TOGGLE_CONTROLNET:
			if is_checkbox_pressed(label):
				set_checkbox_pressed(label, false)
				DiffusionServer.features.uncheck(DiffusionServer.FEATURE_CONTROLNET)
			else:
				set_checkbox_pressed(label, true)
				DiffusionServer.features.check(DiffusionServer.FEATURE_CONTROLNET)
		DEV_TOGGLE_INOUTPAINT:
			if is_checkbox_pressed(label):
				set_checkbox_pressed(label, false)
				DiffusionServer.features.uncheck(DiffusionServer.FEATURE_INPAINT_OUTPAINT)
			else:
				set_checkbox_pressed(label, true)
				DiffusionServer.features.check(DiffusionServer.FEATURE_INPAINT_OUTPAINT)
		DEV_TOGGLE_IMG2IMG:
			if is_checkbox_pressed(label):
				set_checkbox_pressed(label, false)
				DiffusionServer.features.uncheck(DiffusionServer.FEATURE_IMG_TO_IMG)
			else:
				set_checkbox_pressed(label, true)
				DiffusionServer.features.check(DiffusionServer.FEATURE_IMG_TO_IMG)
		DEV_TOGGLE_IMG_INFO:
			if is_checkbox_pressed(label):
				set_checkbox_pressed(label, false)
				DiffusionServer.features.uncheck(DiffusionServer.FEATURE_IMAGE_INFO)
			else:
				set_checkbox_pressed(label, true)
				DiffusionServer.features.check(DiffusionServer.FEATURE_IMAGE_INFO)


func _on_MenuBar_resized():
	yield(get_tree(), "idle_frame")
	var aux = light_dark_theme_button.rect_size.x + show_hide_theme_buttons.rect_size.x
	theme_buttons_center.rect_min_size.x = aux
	theme_buttons_center.rect_size.x = aux


func exit():
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "exit").execute()



class MenuCheckbox extends Reference:
	var menu_popup_owner: PopupMenu = null
	var id: int = -1 # Id within menu in general, as well as in _on_menu_option_selected
	var index: int = -1 # id within popup menu 
	var flag: Flag = null 
	var menu_event_receiver: Object = null
	
	func _init(menu_popup: PopupMenu, id_int: int, index_: int):
		menu_popup_owner = menu_popup
		id = id_int
		index = index_
	
	
	func is_pressed():
		return menu_popup_owner.is_item_checked(index)
	
	
	func set_accelerator(accelerator):
		menu_popup_owner.set_item_accelerator(index, accelerator)
	
	
	func check():
		menu_popup_owner.set_item_checked(index, true)
		if flag != null:
			flag.value = 1
	
	
	func uncheck():
		menu_popup_owner.set_item_checked(index, false)
		if flag != null:
			flag.value = 0
	
	
	func set_flag_name(flag_name: String, menu_event_receiver_):
		if not menu_event_receiver_.has_method("_on_menu_option_selected"):
			l.g("Can't add flag name '" + flag_name + "' to menu checkbox, no valid event receiver")
			return
		
		menu_event_receiver = menu_event_receiver_
		flag = Flags.ref(flag_name)
		flag.set_up(true, null, null, is_pressed())
		Director.connect_global_file_loaded(self, "_on_global_file_loaded")
	
	
	func _on_global_file_loaded():
		# flag.setup must be called alfter global file load since global file replaces
		# all flag data
		update_with_flag()
	
	
	func update_with_flag(_cue: Cue = null):
		var checked = flag.get_value() == 1
		if checked != is_pressed():
			menu_event_receiver._on_menu_option_selected(id)
