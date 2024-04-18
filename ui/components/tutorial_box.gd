extends Panel

onready var textbox = $Panel/VBoxContainer/RichTextLabel
onready var next_button = $Panel/VBoxContainer/HBoxContainer/Next
onready var prev_button = $Panel/VBoxContainer/HBoxContainer/Prev
onready var skip_button = $Panel/VBoxContainer/HBoxContainer/Skip
onready var skip_spacing = $Panel/VBoxContainer/HBoxContainer/Spacing2
onready var frame = $Frame
onready var margin_panel = $Panel

signal prev_pressed
signal next_pressed
signal skip_pressed


func _ready():
	UIOrganizer.add_to_theme_by_modulate_group(frame, Consts.THEME_MODULATE_GROUP_STYLE)


func set_text(text: String, has_prev: bool, has_next: bool, allow_skip: bool = true):
	textbox.text = text
	next_button.grab_focus()
	prev_button.visible = has_prev
	if has_next:
		next_button.text = "NEXT"
		skip_button.visible = allow_skip
		skip_spacing.visible = allow_skip
	else:
		next_button.text = "OK"
		skip_button.visible = false
		skip_spacing.visible = false


func _on_Prev_pressed():
	emit_signal("prev_pressed")


func _on_Next_pressed():
	emit_signal("next_pressed")


func _on_Skip_pressed():
	emit_signal("skip_pressed")


func _on_Panel_resized():
	yield(get_tree(), "idle_frame")
	rect_size = margin_panel.rect_size
