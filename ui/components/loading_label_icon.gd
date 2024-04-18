extends TextureRect

var tween: SceneTreeTween = null

signal animation_started
signal animation_ended

func _ready():
	var e = connect("resized", self, "_on_resized")
	l.error(e, l.CONNECTION_FAILED)


func _on_resized():
	rect_pivot_offset = rect_size / 2


func spin(time):
	visible = true
	if tween == null:
		emit_signal("animation_started")
		tween = create_tween().bind_node(self)
	# warning-ignore:return_value_discarded
		tween.set_loops(0).tween_property(self, "rect_rotation", 360.0, time).from(0.0)


func stop():
	visible = false
	if tween != null:
		emit_signal("animation_ended")
		tween.kill()
		tween = null


func pause():
	if tween != null:
		emit_signal("animation_ended")
		tween.kill()
		tween = null




