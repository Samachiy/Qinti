extends MarginContainer

onready var message_bg = $MessageBackground
onready var msg_apply_copy_button = $MarginContainer/Message/ApplyCopy
onready var msg_apply_button = $MarginContainer/Message/Apply
onready var msg_regenerate_button = $MarginContainer/Message/Regenerate
onready var msg_discard_button = $MarginContainer/Message/Discard
onready var msg_prev_button = $MarginContainer/Message/Prev
onready var msg_next_button = $MarginContainer/Message/Next
onready var message_text = $MarginContainer/Message/Label

var displace_canvas: bool
var y_displacement: int
var preview: Control
var preview_size: int
var preview_margin: int


signal message_area_displayed
signal message_area_displaying
signal message_area_hiding
signal message_area_hidden


func _ready():
	message_bg.modulate.a8 = Consts.ACCENT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(message_bg, Consts.THEME_MODULATE_GROUP_STYLE)
	set_msg_button_modulate(msg_apply_copy_button)
	set_msg_button_modulate(msg_apply_button)
	set_msg_button_modulate(msg_regenerate_button)
	set_msg_button_modulate(msg_discard_button)
	set_msg_button_modulate(msg_prev_button)
	set_msg_button_modulate(msg_next_button)
	set_msg_button_modulate(message_text)
	hide()


func set_msg_button_modulate(button: Control):
	button.modulate.a8 = Consts.ACCENT_CONTRAST_TEXT_A
	UIOrganizer.add_to_theme_by_modulate_group(button, Consts.THEME_MODULATE_GROUP_STYLE)


func get_y_displacement_amount():
	var displacement = (rect_size.y + message_bg.rect_size.y) * 0.5
	if visible and displace_canvas:
		return displacement
	else:
		return 0


func show_area(displace_canvas_: bool, apply_copy_button: bool = true, 
message: String = "APPLY_GEN_MESSAGE"):
	emit_signal("message_area_displaying")
	visible = true
	msg_apply_copy_button.visible = apply_copy_button
	msg_apply_button.grab_focus()
	message_text.text = message
	displace_canvas = displace_canvas_
	preview.extra_margin = Vector2(0, rect_size.y - preview_margin)
	preview.calculate_size()
	emit_signal("message_area_displayed")


func enable_next_prev(enable: bool):
	msg_prev_button.visible = enable
	msg_next_button.visible = enable


func hide_area():
	emit_signal("message_area_hiding")
	visible = false
	displace_canvas = false
	preview.extra_margin = Vector2.ZERO
	preview.calculate_size()
	emit_signal("message_area_hidden") #_on_resized(), not connected, looks fine without it


func connect_message_area(object: Object, apply_method: String, apply_copy_method: String, 
regenerate_method: String, discard_method: String, prev_method: String, next_method: String):
	var error = msg_apply_button.connect("pressed", object, apply_method)
	l.error(error, l.CONNECTION_FAILED + "Apply signal in canvas 2d is not connected")
	error = msg_apply_copy_button.connect("pressed", object, apply_copy_method)
	l.error(error, l.CONNECTION_FAILED + "Apply copy signal in canvas 2d is not connected")
	error = msg_regenerate_button.connect("pressed", object, regenerate_method)
	l.error(error, l.CONNECTION_FAILED + "Regenerate signal in canvas 2d is not connected")
	error = msg_discard_button.connect("pressed", object, discard_method)
	l.error(error, l.CONNECTION_FAILED + "Discard signal in canvas 2d is not connected")
	error = msg_prev_button.connect("pressed", object, prev_method)
	l.error(error, l.CONNECTION_FAILED + "Prev signal in canvas 2d is not connected")
	error = msg_next_button.connect("pressed", object, next_method)
	l.error(error, l.CONNECTION_FAILED + "Next signal in canvas 2d is not connected")
