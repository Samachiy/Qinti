extends ToolController

onready var brush_opacity = $BrushOpacity
onready var brush_size = $BrushSize
onready var denoising_strenght = $DenoisingStrenght
onready var use_modifiers = $GridContainer/UseModifiers
onready var invert_mask = $GridContainer/InvertMask
onready var inpaint_full = $GridContainer/InpaintFullRes
onready var mask_blur = $MaskBlur
onready var inpaint_button = $Inpaint
onready var clear_mask_button = $GridContainer/ClearMask

export(NodePath) var inpaint_eraser
export(bool) var allow_opacity = false

var size = 40
var opacity = 255
var eraser_controller = null
var generation_area = null

func _ready():
	eraser_controller = get_node_or_null(inpaint_eraser)
	if allow_opacity:
		brush_opacity.visible = true
	else:
		brush_opacity.visible = false


func reload_description(_cue: Cue = null):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "add").opts({
		Consts.UI_CONTROL_LEFT_CLICK: Consts.HELP_DESC_PAINT_INPAINT_MASK,
	}).execute()


func left_click(event):
	canvas.paint_mask_line(event.position, true, size, opacity)


func left_click_drag(event):
	canvas.paint_mask_line(event.position, false, size, opacity)


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
	if not button.pressed:
		button.pressed = true
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


func _on_canvas_connected(canvas_node: Node):
	._on_canvas_connected(canvas_node)
	generation_area = canvas_node.generation_area


func inpaint(apply_modifiers):
	var mask: Image = generation_area.get_contained_mask()
	var input_image: Image = generation_area.get_contained_image()
	var config = {
		Consts.I_DENOISING_STRENGTH: denoising_strenght.get_value(),
		# mask is base64 since it's applied directly, no blend
		Consts.I2I_MASK: ImageProcessor.image_to_base64(mask),
		Consts.I2I_MASK_BLUR: mask_blur.get_value(),
		Consts.I2I_INPAINT_FULL_RES: inpaint_full.pressed,
		Consts.I2I_INPAINTING_MASK_INVERT: int(invert_mask.pressed)
	}
	Cue.new(Consts.ROLE_API, "clear").execute()
	DiffusionServer.api.queue_mask_to_bake(mask, input_image, DiffusionAPI.MASK_MODE_INPAINT)
	
	Cue.new(Consts.ROLE_PROMPTING_AREA, "add_prompt_and_seed_to_api").execute()
	Cue.new(Consts.ROLE_CANVAS, "apply_parameters_to_api").execute()
	
	if apply_modifiers:
		Cue.new(Consts.ROLE_GENERATION_INTERFACE, "apply_modifiers_to_api").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_img2img").args([false]).execute()
	Cue.new(Consts.ROLE_API, "bake_pending_mask").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_controlnets").execute()
	Cue.new(Consts.ROLE_API, "apply_parameters").opts(config).execute()
#	Cue.new(Consts.ROLE_API, "bake_pending_regional_prompts").execute()
	
	var prompting_area = Roles.get_node_by_role(Consts.ROLE_PROMPTING_AREA)
	if prompting_area is Object:
		DiffusionServer.generate(prompting_area, "_on_image_generated")
	else:
		l.g("Can't inpaint, there's no node with the role ROLE_PROMPTING_AREA")


func _on_BrushSize_value_changed(value):
	size = value


func _on_BrushOpacity_value_changed(value):
	opacity = value


func _on_DenoisingStrenght_value_changed(value):
	if eraser_controller == null:
		return
	
	eraser_controller.set_denoising_strenght(value)


func _on_InvertMask_toggled(button_pressed):
	if eraser_controller == null:
		return
	
	eraser_controller.set_invert_mask(button_pressed)


func _on_InpaintFullRes_toggled(button_pressed):
	if eraser_controller == null:
		return
	
	eraser_controller.set_inpaint_full_res(button_pressed)


func _on_MaskBlur_value_changed(value):
	if eraser_controller == null:
		return
	
	eraser_controller.set_mask_blur(value)


func _on_UseModifiers_toggled(button_pressed):
	if eraser_controller == null:
		return
	
	eraser_controller.set_use_modifiers(button_pressed)


func _on_AIProcessButton_pressed():
	inpaint(use_modifiers.pressed)


func _on_ClearMask_pressed():
	var layer = canvas.current_layer
	if layer is Layer2D:
		layer.clear_mask()
