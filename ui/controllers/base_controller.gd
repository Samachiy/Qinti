extends Control

class_name Controller

const DESKTOP_ICON_SIZE = 25
const PHONE_ICON_SIZE = 40
const CONTROLLER_MIN_Y_SIZE = 152

var canvas = null
var board_owner = null

export var controller_role = ''
export var auto_role: bool = true
var active_tool = null
var controller_name_only: String = ''
var modifier: ModifierMode = null

signal canvas_connected
signal visible_board_requested


func clear(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'clear' has not been overriden yet on Controller: " + 
	name)


func get_data_cue(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	# This function needs to handle a case where this is called when the information is 
	# not ready yet, make sure to check that the need info to load this is complete
	l.g("The function 'get_data_cue' has not been overriden yet on Controller: " + 
	name)


func set_data_cue(_cue: Cue):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'set_data_cue' has not been overriden yet on Controller: " + 
	name)


func _fill_menu():
	l.g("The function '_fill_menu' has not been overriden yet on Controller: " + 
	filename)


func _on_Menu_option_pressed(_label_id, _index_id):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function '_on_Menu_option_pressed' has not been overriden yet on Controller: " + 
	filename)


func reload_description(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'reload_description' has not been overriden yet on Controller: " + 
	filename)


func add_to_description_group():
	# This function is currently called on:
	# open_board() > signal visible_board_requested to board > show_board() only, 
	# so as too not place it in every single object that opens a board
	add_to_group(Consts.UI_HAS_DESCRIPTION_GROUP)


func remove_from_description_group():
	# This function is currently called on:
	# generation_inderface > hide_boards() > board_child.hide_board() only, 
	# so as too not place it in every single object that opens a board
	remove_from_group(Consts.UI_HAS_DESCRIPTION_GROUP)


func _on_Controller_hiding():
	# This function will be called more times on it's lifespan, program it accordingly
	# This function is not obligatory to override but it's meant to
	pass
	


func _ready():
	rect_min_size.y = CONTROLLER_MIN_Y_SIZE
	if auto_role and controller_role.empty():
		var role_name = format_file_name(name)
		Roles.request_role(self, role_name)
		controller_role = role_name
	elif not controller_role.empty():
		Roles.request_role(self, controller_role)
	else:
		l.g('Missing controller role name in: ' + get_path())


func open_board(cue: Cue = null):
	# [ modifier = null ]
	if cue is Cue:
		modifier = cue.get_at(0, null, false)
	
	Roles.request_role(board_owner, Consts.ROLE_ACTIVE_BOARD, true)
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "hide_boards").args([board_owner]).execute()
	l.p(board_owner.name)
	emit_signal("visible_board_requested")


func format_file_name(file_name: String):
	var resul: String = file_name.capitalize()
	var control_word = "Control"
	controller_name_only = resul.substr(0, resul.find(control_word))
	return controller_name_only + control_word


func add_tool_icon(button_icon: TextureButton):
	# up to the present day, this functions is always called after the 
	# 'canvas_connected' signal is fired. This way we can assign the canvas
	# to the button icon
	
	if button_icon == null:
		l.g("Couldn't load tool icon button. Not valid button icon at: " +
		str(get_path()))
		return
	
	if button_icon.has_signal("tool_selected"):
		board_owner.add_tool_icon(button_icon)
		var error = button_icon.connect("tool_selected", self, "on_tool_selected")
		l.error(error, l.CONNECTION_FAILED)
		button_icon.rect_min_size = get_tool_icon_size_vec2()
	else:
		l.g("Couldn't load tool icon button. The button is not the correct tipe. " +
		"Button: '" + button_icon.name + "' at: " + str(get_path()))




func connect_canvas(canvas_node: Control):
	canvas = canvas_node
	canvas.connect("left_click", self, "_left_click")
	canvas.connect("left_click_drag", self, "_left_click_drag")
	canvas.connect("right_click", self, "_right_click")
	canvas.connect("right_click_drag", self, "_right_click_drag")
	canvas.connect("middle_click", self, "_middle_click")
	canvas.connect("middle_click_drag", self, "_middle_click_drag")
	canvas.connect("scroll_up", self, "_scroll_up")
	canvas.connect("scroll_down", self, "_scroll_down")
	canvas.connect("mouse_button_released", self, "_button_released")
	canvas.connect("mouse_exited_canvas", self, "_exited_canvas")
	canvas.connect("mouse_moved", self, "_mouse_moved")
	emit_signal("canvas_connected", canvas)
	
	# We fill and connect the menu if it exists, if not, we print error
	if canvas.get("menu") == null:
		l.g("Controller '" + filename + "' does not have a menu instanced")
	else:
		canvas.menu.connect("option_selected", self, "_on_Menu_option_pressed")
		_fill_menu()


func get_undoredo_data(_cue: Cue = null):
	if canvas == null:
		return null
	
	var data = canvas.get("undoredo_queue")
	if data is Canvas2DUndoQueue:
		return data
	else:
		return null


func set_undoredo_data(cue: Cue) -> Object:
	if canvas == null:
		return null
	
	var data = cue.get_at(0, null)
	if data is Canvas2DUndoQueue:
		canvas.set("undoredo_queue", data)
		return data
	else:
		if canvas.has_method("create_new_undoredo"):
			return canvas.create_new_undoredo()
		else:
			return null



func on_tool_selected(tool_controller):
	if active_tool != null:
		active_tool.deselect_tool()
		active_tool.remove_from_description_group()
	active_tool = tool_controller
	active_tool.select_tool()
	active_tool.add_to_description_group()


func deselect_tools(_cue: Cue = null):
	if active_tool != null:
		active_tool.deselect_tool()
		active_tool.remove_from_description_group()
		if active_tool.get("button") is BaseButton:
			active_tool.button.pressed = false


func _left_click(event: InputEventMouseButton):
	if active_tool != null:
		active_tool.left_click(event)


func _left_click_drag(event: InputEventMouseMotion):
	if active_tool != null:
		active_tool.left_click_drag(event)


func _right_click(event: InputEventMouseButton):
	if active_tool != null:
		if not active_tool.right_click(event):
			canvas.menu.popup_at_cursor()
	else:
		canvas.menu.popup_at_cursor()


func _right_click_drag(event: InputEventMouseMotion):
	if active_tool != null:
		active_tool.right_click_drag(event)


func _middle_click(event: InputEventMouseButton):
	if active_tool != null:
		active_tool.middle_click(event)


func _middle_click_drag(event: InputEventMouseMotion):
	if active_tool != null:
		if not active_tool.middle_click_drag(event):
			canvas.move_camera_by_mouse_motion(event)
	else:
		canvas.move_camera_by_mouse_motion(event)


func _scroll_up(event: InputEventMouseButton):
	if active_tool != null:
		if not active_tool.scroll_up(event):
			canvas.zoom_in()
	else:
		canvas.zoom_in()


func _scroll_down(event: InputEventMouseButton):
	if active_tool != null:
		if not active_tool.scroll_down(event):
			canvas.zoom_out()
	else:
		canvas.zoom_out()


func _mouse_moved(event: InputEventMouseMotion, is_inside: bool):
	if active_tool != null:
		active_tool.mouse_moved(event, is_inside)


func _button_released(event: InputEventMouseButton):
	if active_tool != null:
		active_tool.button_released(event)


func _exited_canvas():
	if active_tool != null:
		active_tool.exited_canvas()


static func get_tool_icon_size():
	return DESKTOP_ICON_SIZE


static func get_tool_icon_size_vec2():
	return Vector2(DESKTOP_ICON_SIZE, DESKTOP_ICON_SIZE)
