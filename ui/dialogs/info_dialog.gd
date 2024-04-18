extends AcceptDialog

onready var command_textbox = $VBoxContainer/MarginContainer/VBoxContainer/Command/RichTextLabel
onready var command_box = $VBoxContainer/MarginContainer/VBoxContainer/Command
onready var label = $VBoxContainer/MarginContainer/VBoxContainer/Label

func _ready():
	pass # Replace with function body.


func display_text(text: String, command: String = ''):
	if command.empty():
		command_box.visible = false
		command_textbox.text = ""
	else:
		command_box.visible = true
		command_textbox.text = command
	
	label.text = text
	popup_centered_ratio(0.5)


func _on_Copy_pressed():
	OS.set_clipboard(command_textbox.text)
