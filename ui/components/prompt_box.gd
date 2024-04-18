extends TextEdit


onready var label = $Margins/Label

export(String) var info_text = ''

func _ready():
	var error = connect("text_changed", self, "_on_text_changed")
	l.error(error, l.CONNECTION_FAILED)
	#connect("focus_entered", self, "_on_focus_entered")
	#connect("focus_exited", self, "_on_focus_exited")
	label.text = info_text
	#label.modulate = Consts.OPPOSITE_GLASS_A
	#UIOrganizer.add_to_theme_by_modulate_group(label, Consts.THEME_MODULATE_GROUP_STYLE)
	_on_text_changed()


func _on_text_changed():
	if text.empty():
		label.visible = true
	else:
		label.visible = false


func _on_focus_entered():
	label.visible = false


func _on_focus_exited():
	_on_text_changed()


func set_text(new_text: String):
	.set_text(new_text)
	_on_text_changed()
