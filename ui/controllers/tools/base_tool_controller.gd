extends VBoxContainer

class_name ToolController

export(String, FILE, "*.tscn") var tool_button: String

var canvas
var has_canvas: bool = false
var button: BaseButton = null
var controller_owner: Controller = null

func select_tool():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'select_tool' has not been overriden yet on tool: " + name)


func deselect_tool():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'unselect_tool' has not been overriden yet on tool: " + name)


func _ready():
	if owner.has_signal('canvas_connected'):
		var e = owner.connect('canvas_connected', self, '_on_canvas_connected')
		l.error(e, l.CONNECTION_FAILED)


func reload_description(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'reload_description' has not been overriden yet on Controller: " + 
	filename)


func add_to_description_group():
	# Important: this is must be called along with select_tool() by whatever object is
	# selecting the tool
	add_to_group(Consts.UI_HAS_DESCRIPTION_GROUP)


func remove_from_description_group():
	# Important: this is must be called along with deselect_tool() by whatever object is
	# deselecting the tool
	if is_in_group(Consts.UI_HAS_DESCRIPTION_GROUP):
		remove_from_group(Consts.UI_HAS_DESCRIPTION_GROUP)


func left_click(_event: InputEventMouseButton):
	return false

func left_click_drag(_event: InputEventMouseMotion):
	return false

func right_click(_event: InputEventMouseButton):
	return false

func right_click_drag(_event: InputEventMouseMotion):
	return false

func middle_click(_event: InputEventMouseButton):
	return false

func middle_click_drag(_event: InputEventMouseMotion):
	return false

func scroll_up(_event: InputEventMouseButton):
	return false

func scroll_down(_event: InputEventMouseButton):
	return false

func button_released(_event: InputEventMouseButton):
	return false

func exited_canvas():
	return false

func mouse_moved(_event: InputEventMouseMotion, _is_inside: bool):
	return false


func _on_canvas_connected(canvas_node: Node):
	var button_packed_scene: PackedScene = load(tool_button)
	if button_packed_scene == null:
		l.g("Couldn't load tool icon button. Not valid button scene: " 
		+ tool_button)
		return
		
	var icon_button = button_packed_scene.instance()
	icon_button.set("tool_controller", self)
	if icon_button.get("tool_controller") == null:
		l.g("tool controller is null for the button: " + name)
	
	button = icon_button
	if owner is Controller:
		controller_owner = owner
		owner.add_tool_icon(icon_button)
	set_canvas(canvas_node)


func set_canvas(canvas_node):
	if canvas_node != null:
		canvas = canvas_node
		has_canvas = true
