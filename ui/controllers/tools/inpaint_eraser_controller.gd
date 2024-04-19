extends ToolController

onready var brush_opacity = $BrushOpacity
onready var brush_size = $BrushSize
onready var denoising_strenght = $DenoisingStrenght
onready var use_modifiers = $GridContainer/UseModifiers
onready var invert_mask = $GridContainer/InvertMask
onready var inpaint_full = $GridContainer/InpaintFullRes
onready var mask_blur = $MaskBlur

export(NodePath) var inpaint_brush
export(bool) var allow_opacity = false

var size = 40
var opacity = 255
var brush_controller = null
var generation_area = null

func _ready():
	brush_controller = get_node_or_null(inpaint_brush)
	if allow_opacity:
		brush_opacity.visible = true
	else:
		brush_opacity.visible = false


func reload_description(_cue: Cue = null):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "add").opts({
		Consts.UI_CONTROL_LEFT_CLICK: Consts.HELP_DESC_ERASE_INPAINT_MASK,
	}).execute()


func left_click(event):
	canvas.erase_mask_line(event.position, true, size, opacity)


func left_click_drag(event):
	canvas.erase_mask_line(event.position, false, size, opacity)


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
	canvas.show_mask()
	visible = true


func deselect_tool():
	canvas.hide_all_masks()
	visible = false
	canvas.pointer.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_denoising_strenght(value):
	if denoising_strenght.get_value() != value:
		denoising_strenght.set_value(value)


func set_invert_mask(value):
	if invert_mask.pressed != value:
		invert_mask.pressed = value


func set_inpaint_full_res(value):
	if inpaint_full.pressed != value:
		inpaint_full.pressed = value


func set_mask_blur(value):
	if mask_blur.get_value() != value:
		mask_blur.set_value(value)


func set_use_modifiers(value):
	if use_modifiers.pressed != value:
		use_modifiers.pressed = value


func _on_BrushSize_value_changed(value):
	size = value


func _on_BrushOpacity_value_changed(value):
	opacity = value


func _on_DenoisingStrenght_value_changed(value):
	if brush_controller == null:
		return
	
	brush_controller.set_denoising_strenght(value)


func _on_InvertMask_toggled(button_pressed):
	if brush_controller == null:
		return
	
	brush_controller.set_invert_mask(button_pressed)


func _on_InpaintFullRes_toggled(button_pressed):
	if brush_controller == null:
		return
	
	brush_controller.set_inpaint_full_res(button_pressed)


func _on_MaskBlur_value_changed(value):
	if brush_controller == null:
		return
	
	brush_controller.set_mask_blur(value)


func _on_UseModifiers_toggled(button_pressed):
	if brush_controller == null:
		return
	
	brush_controller.set_use_modifiers(button_pressed)


func _on_AIProcessButton_pressed():
	if brush_controller == null:
		return
	
	brush_controller.inpaint(use_modifiers.pressed)


func _on_ClearMask_pressed():
	var layer = canvas.current_layer
	if layer is Layer2D:
		layer.clear_mask()
