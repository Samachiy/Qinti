extends TextureButton

var theme_data: ThemeData = null

signal theme_selected(theme_data)


func set_theme_data(theme_data_: ThemeData):
	theme_data = theme_data_
	modulate = theme_data.preview_color


func _on_ColorButton_pressed():
	if theme_data != null:
		emit_signal("theme_selected", theme_data)
