extends Controller

const WARNING_IMAGE_PATH = "res://qinti_default.png"

onready var scroll = $Container
onready var top_gradient = $TopGradient
onready var bottom_gradient = $BottomGradient
onready var command_textbox = $Container/Info/Command/RichTextLabel
onready var command_box = $Container/Info/Command
onready var label = $Container/Info/Label

var warning_image_obj: Texture
var warning_image_data: ImageData = null



func _ready():
	var error = connect("canvas_connected", self, "prepare_canvas")
	l.error(error, l.CONNECTION_FAILED)
	
	warning_image_obj = load(ProjectSettings.globalize_path(WARNING_IMAGE_PATH))
	warning_image_data = ImageData.new("default_image")
	warning_image_data.load_texture(warning_image_obj)
	# Adding the scroll indicators
	if scroll is ScrollContainer and top_gradient != null and bottom_gradient != null:
		var gradient_group = Consts.THEME_MODULATE_GROUP_STYLE
		UIOrganizer.add_to_theme_by_modulate_group(top_gradient, gradient_group)
		UIOrganizer.add_to_theme_by_modulate_group(bottom_gradient, gradient_group)
		scroll.get_v_scrollbar().connect("changed", self, "_on_scroll_changed")


func prepare_canvas(_cue: Cue = null):
	canvas.set_image_data(warning_image_data)


func clear(_cue: Cue = null):
	pass


func _on_scroll_changed():
	var scrollbar = scroll.get_v_scrollbar()
	UIOrganizer.show_v_scroll_indicator(scrollbar, top_gradient, bottom_gradient, 8)


func display_error(cue: Cue):
	# [ text, info_to_copy, extra_text, extra_info_to_copy ]
	var text = cue.str_at(0, '')
	var info = cue.str_at(1, '', false)
	var extra_text = cue.str_at(0, '')
	var extra_info = cue.str_at(1, '', false)
	display_text(text, info)


func display_text(text: String, command: String = ''):
	if command.empty():
		command_box.visible = false
		command_textbox.text = ""
	else:
		command_box.visible = true
		command_textbox.text = command
	
	label.text = text


func _on_Copy_pressed():
	OS.set_clipboard(command_textbox.text)
