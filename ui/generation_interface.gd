extends Panel

const MSG_SHUTTING_DOWN_SERVER = "MESSAGE_SHUTTING_DOWN_SERVER"
const MSG_CALCULATING_HASHES = "MESSAGE_CALCULATING_HASHES"
const LINUX_SCRIPTS_PATH = "res://dependencies/scripts/system/"

onready var board_container = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Boards
onready var modifiers_container = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Modifiers
onready var top_bar_spacing = $MarginContainer/VBoxContainer/TopBarSpacing
onready var menu_bar = $Bars/MenuBar
onready var bottom_bar_spacing = $MarginContainer/VBoxContainer/BottomBarSpacing
onready var description_bar = $Bars/DescriptionBar
onready var main_margin = $MarginContainer
onready var forced_close_timer = $ForcedCloseTimer

var prev_board = null
var main_board = null
var windows_ready: bool = false
var server_ready: bool = false
var restore_flags: Dictionary = {}
var current_project_path: String = ''
var current_save_settings: Dictionary = {}
var confirm_current_settings: bool = false

func _ready():
	var error = get_tree().connect("files_dropped", self, "_on_files_dropped")
	l.error(error, l.CONNECTION_FAILED)
	Roles.request_role(self, Consts.ROLE_GENERATION_INTERFACE)
	Roles.request_role(Consts.UI_DROP_GROUP, Consts.UI_DROP_GROUP)
	Roles.request_role(Consts.UI_CANVAS_WITH_SHADOW_AREA, Consts.UI_CANVAS_WITH_SHADOW_AREA)
	Roles.request_role(Consts.UI_AI_PROCESS_ONGOING_GROUP, Consts.UI_AI_PROCESS_ONGOING_GROUP)
	Roles.request_role(Consts.UI_HAS_DESCRIPTION_GROUP, Consts.UI_HAS_DESCRIPTION_GROUP)
	Roles.request_role(Consts.UI_UPDATE_FLAG_ON_LOAD_GROUP, Consts.UI_UPDATE_FLAG_ON_LOAD_GROUP)
	Roles.request_role(
			Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP, 
			Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP)
	UIOrganizer.set_locale('en')
	Director.connect_game_closing(self, "_on_game_closing")
	Director.connect_game_pre_closing(self, "_on_game_pre_closing")
	Director.connect_file_load_requested(self, "_on_file_load_requested")
	var e = DiffusionServer.connect("server_ready", self, "_on_server_ready")
	l.error(e, l.CONNECTION_FAILED)
	detect_main_board()
	show_main_board()
	if OS.has_feature("standalone"):
		l.g("Release version: " + Director.get_current_version_string(), l.INFO)
	else:
		l.g("Program doesn't have standalone feature", l.INFO)


func get_open_board(_cue: Cue = null):
	var board_child
	var is_board
	for child in board_container.get_children():
		# The board has a wrapper, so we need to get the wrapper child
		board_child = child.get_child(0) 
		
		is_board = board_child is Control and board_child.has_method("show_board")
		if not is_board:
			continue
			
#		if child.visible and board_child != main_board:
#			prev_board = board_child
		
		if child.visible:
			return board_child


func hide_boards(cue: Cue = null):
	# [ next_board_to_show: Node ]
	var current_board = Roles.get_node_by_role(Consts.ROLE_ACTIVE_BOARD)
	var next_board = cue.get_at(0)
	if current_board != next_board:
		prev_board = current_board
	
	var board_child
	var is_board
	for child in board_container.get_children():
		# The board has a wrapper, so we need to get the wrapper child
		board_child = child.get_child(0) 
		
		is_board = board_child is Control and board_child.has_method("show_board")
		if not is_board:
			continue
		
		if board_child == next_board:
			# Current board should always be showing
			continue
#		if child.visible and board_child != main_board:
#			prev_board = board_child
		
		if child.visible:
			board_child.hide_board()


func show_modifier_board(_cue: Cue = null):
	var prev_board_modifier: Modifier = Roles.get_node_by_role(Consts.ROLE_ACTIVE_MODIFIER)
	if prev_board_modifier == null:
		return

#	hide_boards(Cue.new("", "").args([prev_board]))
	prev_board_modifier.select() # Select already hides the board (calls open_board)


func show_main_board(_cue: Cue = null):
	if main_board == null:
		return
	
	#hide_boards(Cue.new("", "").args([main_board]))
	var prev_board_modifier = Roles.get_node_by_role(Consts.ROLE_ACTIVE_MODIFIER, false)
	if prev_board_modifier == null:
		Cue.new(Consts.ROLE_CANVAS, "open_board").execute()
		# main_board.show_board() # we use the cue rather than using show_board()
		# because open_board also sets role_active_board and hides the boards
		main_board.hide_alt_board_switch()
	else:
		prev_board_modifier.deselect()
		Cue.new(Consts.ROLE_CANVAS, "open_board").execute()
		# main_board.show_board() # we use the cue rather than using show_board()
		# because open_board also sets role_active_board and hides the boards
		main_board.show_alt_board_switch()


func detect_main_board():
	var board_child
	var is_board
	for child in board_container.get_children():
		# The board has a wrapper, so we need to get the wrapper child
		board_child = child.get_child(0)
		
		is_board = board_child is Control and board_child.has_method("show_board")
		if is_board and board_child.get("is_main_board"): # null is counted as false
			main_board = board_child


func apply_modifiers_to_api(_cue: Cue = null):
	modifiers_container.apply_modifiers_to_api()


#func generate(cue: Cue = null):
#	# [object_to_receive_resul: Object, function_to_receive_resul: String]
#	var object = cue.get_at(0, null)
#	var function = cue.get_at(1, '')
#	if object is Object:
#		DiffusionServer.generate(object, function)


func _on_Main_ready():
	Director.scene_load_ready(false)
	if Consts.pc_data.is_linux():
		PCData.make_file_executable_recursive(PCData.globalize_path(LINUX_SCRIPTS_PATH))


func save_as(cue: Cue):
	# [ use_current_path ]
	var use_current_path = cue.bool_at(0, false)
	var dir = Directory.new()
	if use_current_path and dir.file_exists(current_project_path):
		if confirm_current_settings:
			request_save_settings(current_project_path)
		else:
			save_file(current_project_path, current_save_settings)
	else:
		Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
				self,
				"request_save_settings",
				FileDialog.MODE_SAVE_FILE
			]).opts({
				tr("SUPPORTED_SAVE_PROJECT_FORMAT"): "*.qps"
			}).execute()


func request_save_settings(path: String):
	if not current_save_settings.empty():
		Cue.new(Consts.ROLE_SAVE_SETTINGS,  "set_settings").opts(
				current_save_settings
		).execute()
	
	Cue.new(Consts.ROLE_SAVE_SETTINGS,  "request_settings").args([
			self,
			"save_file",
			path
		]).execute()
	


func save_file(path: String, save_settings: Dictionary):
	# Setting the save settings
	var recent_img_amount = save_settings.get(SaveSettingsUI.RECENT_IMG_AMOUNT, -1)
	if recent_img_amount != -1:
		Cue.new(Consts.ROLE_TOOLBOX, "set_recent_img_save_amount").args([
				recent_img_amount
		]).execute()
	
	
	Director.set_up_locker(Consts.SAVE)
	# show load messages that says: Calculating and storing models ID
	Cue.new(Consts.ROLE_DIALOGS, "request_load_message").args([
			MSG_CALCULATING_HASHES
	]).execute()
	# Solve hashes
	HashCalculator.pause_hashing_thread()
	HashCalculator.switch_to_fast_queue()
	Cue.new(Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP, "queue_hash_now").execute()
	Cue.new(Consts.ROLE_MODIFIERS_AREA, "queue_hash_now").execute()
	yield(HashCalculator.start_hashing_thread(), "fast_queue_finished")
	Cue.new(Consts.ROLE_DIALOGS, "close_load_message").execute()
	
	# Call Active board > controller_node > consolidate data (if it has such method)
	Cue.new(Consts.ROLE_ACTIVE_BOARD, "consolidate_canvas").execute()
	
	# Call SaveLoad
	current_project_path = path
	confirm_current_settings = false
	Director.save_file_at_path(path)


func load_from(_cue: Cue = null):
	Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
			self,
			"load_file",
			FileDialog.MODE_SAVE_FILE
		]).opts({
			tr("SUPPORTED_SAVE_PROJECT_FORMAT"): "*.qps"
		}).execute()


func load_file(path: String):
	current_project_path = path
	Cue.new(Consts.ROLE_ACTIVE_MODIFIER, "deselect").execute(false)
	Director.load_file_at_path(path)
	Director.use_up_locker(Consts.SAVE)
	Cue.new(Consts.UI_UPDATE_FLAG_ON_LOAD_GROUP, "update_with_flag").execute()
	Cue.new(Consts.ROLE_CANVAS, "open_board").execute()
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
			Consts.HELP_DESC_SAVE_FILE_LOADED]).execute()


func _on_files_dropped(files: PoolStringArray, _screen: int):
	if files.size() >= 1:
		var file_path: String = files[0]
		var extension = file_path.get_extension()
		if extension == "qps":
			load_file(file_path)


func exit(_cue: Cue = null):
	get_tree().root.propagate_notification(NOTIFICATION_WM_QUIT_REQUEST)


func set_on_top(cue: Cue):
	# Used for the drag and drop preview
	# [ node ]
	var node = cue.get_at(0, null)
	if not node is Node:
		return
	
	var node_parent = node.get_parent()
	if node_parent is Node:
		remove_child(node)
	
	get_parent().add_child(node)


func _on_DescriptionBar_visibility_changed():
	bottom_bar_spacing.visible = description_bar.visible


func _on_MenuBar_hiding_toggled(is_hiding_value):
	top_bar_spacing.visible = not is_hiding_value


func _on_MarginContainer_resized():
	if main_board == null:
		return
	
	if not windows_ready:
		_print_window_size_info('', l.DEBUG)
		if OS.has_feature("standalone"):
			OS.window_maximized = true
		windows_ready = true


func _print_window_size_info(extra_message: String, level = l.INFO):
	l.g("Initial size set as: " + str(main_margin.rect_size) + " with minimum size of " + 
			str(OS.min_window_size) + ". " + extra_message, level)


func _on_server_ready():
	server_ready = true


func _on_game_pre_closing():
	if restore_flags.empty():
		return
	
	load_flag_data(restore_flags.duplicate())


func _on_game_closing():
#	if not OS.has_feature("standalone"):
#		get_tree().quit()
#		return
	
	l.g("Closing program", l.INFO)
	forced_close_timer.start()
	Cue.new(Consts.ROLE_DIALOGS, "request_load_message").args([MSG_SHUTTING_DOWN_SERVER]).execute()
	if server_ready:
		l.g("Attempting server stop before shutdown", l.INFO)
		yield(DiffusionServer.server.stop_server(), "server_stopped")
		get_tree().quit()
	else:
		l.g("Attempting Python process stop before shutdown", l.INFO)
		Python.kill()
		get_tree().quit()


func _on_ForcedCloseTimer_timeout():
	l.g("Forced close timeout reached, server may still be active", l.INFO)
	get_tree().quit()



func _save_cues(_is_file_save):
	var flags = Flags.flag_catalog
	flags.erase(Consts.I_SAMPLER_NAME)
	Director.add_save_cue(Consts.SAVE, Consts.ROLE_GENERATION_INTERFACE, "load_parameters", [], flags)


func load_parameters(cue: Cue):
	# [ save_parameters ]
	# All the other parameters/flags are in cue options
	var param_flags: Dictionary = cue._options
	load_flag_data(param_flags)
	current_save_settings = cue.get_at(0, {}, false) # RESUME remove the last arguments once old saves are replaced
	confirm_current_settings = true


func load_flag_data(data: Dictionary):
	var flag: Flag
	for flag_name in data:
		flag = Flags.ref(flag_name)
		flag.set_value(data[flag_name][Flag.VALUE])


func _on_file_load_requested(_path):
	if restore_flags.empty():
		restore_flags = Flags.flag_catalog.duplicate()
	
