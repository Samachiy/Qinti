extends Control

class_name DropArea

signal modifier_dropped(position, modifier)
signal modifier_drop_attempted(position, drop_area)
signal drop_attempt_finished()


var listen_to_mouse_release = false


func _ready():
	var error = connect("mouse_exited", self, "_on_mouse_exited")
	l.error(error, l.CONNECTION_FAILED)
	add_to_group(Consts.UI_DROP_GROUP)
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(_delta):
	if listen_to_mouse_release:
		if not Input.is_mouse_button_pressed(BUTTON_LEFT):
			Cue.new(Consts.UI_DROP_GROUP, "disable_drop").execute()


func can_drop_data(position: Vector2, data):
	if data is Modifier:
		emit_signal("modifier_drop_attempted", position, self)
		return true
	else:
		return false


func drop_data(position, data):
	emit_signal("modifier_dropped", position, data)


func enable_drop(_cue: Cue = null):
	mouse_filter = MOUSE_FILTER_STOP
	listen_to_mouse_release = true


func disable_drop(_cue: Cue = null):
	emit_signal("drop_attempt_finished")
	mouse_filter = MOUSE_FILTER_IGNORE
	listen_to_mouse_release = false


func connect_on_attempt_finished(object: Object, method: String, oneshot: bool = true):
	if not is_connected("drop_attempt_finished", object, method):
		if oneshot:
			var e = connect("drop_attempt_finished", object, method, [], CONNECT_ONESHOT)
			l.error(e, l.CONNECTION_FAILED)
		else:
			var e = connect("drop_attempt_finished", object, method)
			l.error(e, l.CONNECTION_FAILED)


func _on_mouse_exited():
	emit_signal("drop_attempt_finished")
