extends Panel

const MSG_SHUTTING_DOWN_SERVER = "MESSAGE_SHUTTING_DOWN_SERVER"
const LINUX_SCRIPTS_PATH = "res://dependencies/scripts/system/"

onready var board_container = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Boards
onready var modifiers_container = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Modifiers
onready var top_bar_spacing = $MarginContainer/VBoxContainer/TopBarSpacing
onready var menu_bar = $Bars/MenuBar
onready var bottom_bar_spacing = $MarginContainer/VBoxContainer/BottomBarSpacing
onready var description_bar = $Bars/DescriptionBar
onready var main_margin = $MarginContainer
onready var forced_close_timer = $ForcedCloseTimer

#var prev_board = null
var main_board = null
var windows_ready: bool = false
var server_ready: bool = false

func _ready():
	Roles.request_role(self, Consts.ROLE_GENERATION_INTERFACE)
	Roles.request_role(Consts.UI_DROP_GROUP, Consts.UI_DROP_GROUP)
	Roles.request_role(Consts.UI_CANVAS_WITH_SHADOW_AREA, Consts.UI_CANVAS_WITH_SHADOW_AREA)
	Roles.request_role(Consts.UI_AI_PROCESS_ONGOING_GROUP, Consts.UI_AI_PROCESS_ONGOING_GROUP)
	Roles.request_role(Consts.UI_HAS_DESCRIPTION_GROUP, Consts.UI_HAS_DESCRIPTION_GROUP)
	Roles.request_role(
			Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP, 
			Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP)
	UIOrganizer.set_locale('en')
	Director.connect_game_closing(self, "_on_game_closing")
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


func hide_boards(_cue: Cue = null):
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
			board_child.hide_board()


func show_modifier_board(_cue: Cue = null):
	var prev_board_modifier: Modifier = Roles.get_node_by_role(Consts.ROLE_ACTIVE_MODIFIER)
	if prev_board_modifier == null:
		return

	hide_boards()
	prev_board_modifier.select()
#	prev_board.show_board()
#	prev_board.show_alt_board_switch()


func show_main_board(_cue: Cue = null):
	if main_board == null:
		return
	
	hide_boards()
	var prev_board_modifier = Roles.get_node_by_role(Consts.ROLE_ACTIVE_MODIFIER, false)
	if prev_board_modifier == null:
		main_board.show_board()
		main_board.hide_alt_board_switch()
	else:
		prev_board_modifier.deselect()
		main_board.show_board()
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


func generate(cue: Cue = null):
	# [object_to_receive_resul: Object, function_to_receive_resul: String]
	var object = cue.get_at(0, null)
	var function = cue.get_at(1, '')
	if object is Object:
		DiffusionServer.generate(object, function)


func _on_Main_ready():
	Director.scene_load_ready(false)
	PCData.make_file_executable_recursive(PCData.globalize_path(LINUX_SCRIPTS_PATH))


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
