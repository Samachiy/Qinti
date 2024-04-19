extends Control

signal active_area_resized(vector2)

func _ready():
	var error = connect("resized", self, "_on_resized")
	l.error(error, l.CONNECTION_FAILED)


func _on_resized():
	emit_signal("active_area_resized", rect_size)
