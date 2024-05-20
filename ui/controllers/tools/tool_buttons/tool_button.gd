extends TextureButton

# Steps to make a new button with this script:
# 	set to expand
# 	 set to keep aspect
# 	set as toggle
# 	set the right group

export(bool) var has_right_click = false
export(String) var bind_feature = ''

var tool_controller = null
#var pressed_right: bool = false
var pressed_left: bool = false

signal tool_selected(tool_controller)
signal extra_options_selected

func _ready():
	var error = connect("toggled", self, "_on_toggled")
	l.error(error, l.CONNECTION_FAILED)
	if has_right_click:
		error = connect("gui_input", self, "_on_gui_input")
		l.error(error, l.CONNECTION_FAILED)
	
	modulate.a8 = Consts.ACCENT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(self, Consts.THEME_MODULATE_GROUP_STYLE)
	if not bind_feature.empty():
		var ds = DiffusionServer
		ds.connect_feature(bind_feature, self, "_on_bind_feature_toggled")


func _on_bind_feature_toggled(enabled: bool):
	visible = enabled
	if pressed and not enabled:
		if not tool_controller is ToolController:
			return
		
		var main_controller = tool_controller.owner
		if main_controller != null and main_controller.has_method("select_main_tool"):
			main_controller.select_main_tool()
		else:
			l.g("Tool button '" + filename + "' is binded to a feature but the main controller " + 
					"doesn't have a main tool to fallback to", l.WARNING)
			


func _on_toggled(pressed: bool):
	if pressed:
		emit_signal("tool_selected", tool_controller)


func _on_gui_input(event):
	if not event is InputEventMouseButton:
		return
	
	if event.get_button_index() == BUTTON_LEFT:
		if pressed_left and not event.pressed:
			emit_signal("extra_options_selected")
		
		pressed_left = event.pressed


#func set_canvas(node):
#	if tool_controller != null:
#		tool_controller.set_canvas(node)
#	else:
#		l.g("tool controller is null for the button: " + name)
