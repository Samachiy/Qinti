extends TextureButton


# DEPRECATED, all of it, color picker now works fine with just color_picker_button.gd

#var temporal_connections: Array = []
#
#signal eyedropper_color_selected(color)
#
#
#func _ready():
#	visible = false
#	Roles.request_role(self, Consts.ROLE_COLOR_PICKER_SERVICE)
#	var error = connect("pressed", self, "_on_pressed")
#	l.error(error, l.CONNECTION_FAILED)
#
#
#func _on_pressed():
#	var click_pos: Vector2 = get_global_mouse_position()
#	var screenshot: Image = get_viewport().get_texture().get_data()
#	screenshot.flip_y()
#	screenshot.lock()
#	var color = screenshot.get_pixel(int(click_pos.x), int(click_pos.y))
#	screenshot.unlock()
#	if color is Color:
#		emit_signal("eyedropper_color_selected", color)
#
#	hide()
#
#
#
#func request_eyedropper(cue: Cue):
#	# [requesting_node, signal_function]
#	var requesting_node = cue.get_at(0, null)
#	var signal_function = cue.get_at(1, '')
#	var error = temporal_connect("eyedropper_color_selected", 
#			requesting_node, signal_function)
#	l.error(error, "Couldn't open color picker eyedropper. Request data: " + 
#			str(requesting_node) + " " + 
#			str(signal_function))
#
#	show()
#
#
#func temporal_connect(signal_name: String, object: Object, method: String):
#	temporal_connections.append([signal_name, object, method]) 
#	return connect(signal_name, object, method, [], CONNECT_ONESHOT)
#
#
#func show():
#	visible = true
#
#
#func hide():
#	for signal_data in temporal_connections:
#		# signal_data: [signal_name, object, method]
#		if is_connected(signal_data[0], signal_data[1], signal_data[2]):
#			disconnect(signal_data[0], signal_data[1], signal_data[2])
#
#	temporal_connections.clear()
#	visible = false
