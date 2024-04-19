extends WindowDialog


onready var label = $VBoxContainer/MarginContainer/VBoxContainer/Label
onready var loading_icon = $VBoxContainer/MarginContainer/VBoxContainer/LoadingLabel


func _ready():
	var e = connect("popup_hide", self, "_on_popup_hide")
	l.error(e, l.CONNECTION_FAILED)


func display_text(text: String):
	label.text = text
	loading_icon.start_animation()
	popup_centered_minsize(Vector2(200, 200))


func _on_popup_hide():
	loading_icon.stop_animation()
	
