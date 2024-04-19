extends Button

onready var selected_frame = $SelectedFrame
onready var hover_indicator = $HoverIndicator

signal thumbnail_selected(index)

var index: int = 0


var is_pressed

func _ready():
	selected_frame.visible = false
	hover_indicator.visible = false
	selected_frame.modulate.a8 = Consts.ACCENT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(
			selected_frame, Consts.THEME_MODULATE_GROUP_STYLE)
	hover_indicator.modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
	UIOrganizer.add_to_theme_by_modulate_group(
			hover_indicator, Consts.THEME_MODULATE_GROUP_STYLE)


func highlight():
	selected_frame.visible = true


func remove_highlight():
	selected_frame.visible = false


func _on_Thumbnail_mouse_entered():
	hover_indicator.visible = true


func _on_Thumbnail_mouse_exited():
	hover_indicator.visible = false


func _on_Thumbnail_focus_entered():
#	highlight()
	emit_signal("thumbnail_selected", index)


func _on_Thumbnail_focus_exited():
#	remove_highlight()
	pass


func _on_Thumbnail_gui_input(event):
	if event is InputEventMouseButton and event.get_button_index() == BUTTON_LEFT:
		if is_pressed and not event.pressed:
			emit_signal("thumbnail_selected", index)
			grab_focus()
		
		is_pressed = event.pressed


