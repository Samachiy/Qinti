tool
extends MarginContainer

onready var text_label = $TextClip/ButtonLabel
onready var load_icon_inner = $LoadIcon/Inner
onready var load_icon_mid = $LoadIcon/Mid
onready var load_icon_outer = $LoadIcon/Outer


export(String) var text = '' setget set_text

signal pressed
signal animation_started
signal animation_ended

func _ready():
	if not Engine.editor_hint:
		text_label.modulate.a8 = Consts.ACCENT_CONTRAST_TEXT_A
		UIOrganizer.add_to_theme_by_modulate_group(
				text_label, Consts.THEME_MODULATE_GROUP_STYLE)


func set_text(value):
	text = value
	if Engine.editor_hint:
		$TextClip/ButtonLabel.text = value
	elif text_label != null:
		text_label.text = text


func start_animation(_cue: Cue = null):
	text_label.visible = false
	load_icon_inner.spin(3)
	load_icon_mid.spin(2.1)
	load_icon_outer.spin(1.5)


func stop_animation(_cue: Cue = null):
	text_label.visible = true
	load_icon_inner.stop()
	load_icon_mid.stop()
	load_icon_outer.stop()

func pause_animation(_cue: Cue = null):
	load_icon_inner.pause()
	load_icon_mid.pause()
	load_icon_outer.pause()


func _on_AIProcessButton_pressed():
	emit_signal("pressed")


func _on_Outer_animation_ended():
	emit_signal("animation_ended")


func _on_Outer_animation_started():
	emit_signal("animation_started")
