extends ToolController

onready var color_picker = $GridContainer/ColorPicker
onready var color_picker_button = $GridContainer/ColorPicker/PanelContainer/ColorPickerButton
onready var brush_opacity = $BrushOpacity
onready var brush_size = $BrushSize
onready var brush_greyscale = $GreyscaleLightness
onready var denoising_strenght = $DenoisingStrenght
onready var use_modifiers = $GridContainer/UseModifiers
onready var q_img2img_module = $QuickImg2ImgModule
onready var q_img2img_button = $QuickImg2Img

export(Color) var default_color = Color.black
export(bool) var allow_change_color = true
#export(bool) var allow_opacity = true
export(bool) var is_greyscale = false
export(bool) var invert_greyscale = false
export(NodePath) var eraser

var eraser_controller
var current_color: Color = Color.black
var size = 40

func _ready():
	eraser_controller = get_node_or_null(eraser)
	current_color = default_color
	color_picker_button.edit_alpha = false
	if allow_change_color:
		# set to false since the color picker will handle opacity
		color_picker.visible = true
		brush_opacity.visible = false
		brush_greyscale.visible = false
	else:
		color_picker.visible = false
		brush_opacity.visible = false
#		if allow_opacity:
#			brush_opacity.visible = true
#		else:
#			brush_opacity.visible = false
		if is_greyscale:
			brush_greyscale.visible = true
		else:
			brush_greyscale.visible = false
	


func reload_description(_cue: Cue = null):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "add").opts({
		Consts.UI_CONTROL_LEFT_CLICK: Consts.HELP_DESC_PAINT,
	}).execute()


func left_click(event):
	# opacity is in the color
	canvas.paint_line(event.position, current_color, true, size) 
	return true


func left_click_drag(event):
	canvas.paint_line(event.position, current_color, false, size)
	return true


func right_click(_event):
	canvas.pointer.clear()
	return false


func exited_canvas():
	canvas.pointer.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	return true


func mouse_moved(event, _is_inside):
	if not canvas.menu.visible:
		canvas.pointer.draw_circle_pointer(canvas.convert_position(event.position), size)
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		canvas.pointer.clear()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	return true


func select_tool():
	visible = true


func deselect_tool():
	visible = false
	canvas.pointer.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_ColorPickerButton_color_changed(color):
	current_color = color
#	if not allow_opacity:
#		current_color.a = 1
	current_color.a = 1


func _on_BrushSize_value_changed(value):
	size = value


func _on_BrushOpacity_value_changed(value):
	current_color.a8 = value


func _on_GreyscaleLightness_value_changed(value):
	if not invert_greyscale:
		value = 255 - value
	
	current_color.r8 = value
	current_color.g8 = value
	current_color.b8 = value


func _on_canvas_connected(canvas_node: Node):
	._on_canvas_connected(canvas_node)
	denoising_strenght.visible = q_img2img_module.is_main_board(canvas)
	use_modifiers.visible = q_img2img_module.is_main_board(canvas)
	q_img2img_button.visible = q_img2img_module.is_main_board(canvas)


func _on_QuickImg2Img_pressed():
	q_img2img_module.quick_image_to_image(
			use_modifiers.pressed, 
			canvas, 
			denoising_strenght.get_value()
	)


func _on_UseModifiers_visibility_changed():
	use_modifiers.visible = use_modifiers.visible and \
			q_img2img_module.is_main_board(canvas)


func _on_DenoisingStrenght_visibility_changed():
	denoising_strenght.visible = denoising_strenght.visible and \
			q_img2img_module.is_main_board(canvas)


func set_denoising_strenght(value):
	if denoising_strenght.get_value() != value:
		denoising_strenght.set_value(value)


func set_use_modifiers(value):
	if use_modifiers.pressed != value:
		use_modifiers.pressed = value


func _on_DenoisingStrenght_value_changed(value):
	if eraser_controller == null:
		return
	
	eraser_controller.set_denoising_strenght(value)


func _on_UseModifiers_toggled(button_pressed):
	if eraser_controller == null:
		return
	
	eraser_controller.set_use_modifiers(button_pressed)
