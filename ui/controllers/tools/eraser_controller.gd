extends ToolController

onready var brush_opacity = $BrushOpacity
onready var brush_size = $BrushSize
onready var denoising_strenght = $DenoisingStrenght
onready var use_modifiers = $GridContainer/UseModifiers
onready var q_img2img_module = $QuickImg2ImgModule
onready var q_img2img_button = $QuickImg2Img

export(NodePath) var brush

var brush_controller
var size = 10
var opacity = 255

func _ready():
	brush_controller = get_node_or_null(brush)
	size = brush_size.get_value()
	opacity = brush_opacity.get_value()


func reload_description(_cue: Cue = null):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "add").args([9]).opts({
		Consts.UI_CONTROL_LEFT_CLICK: Consts.HELP_DESC_ERASE,
	}).execute()


func left_click(event):
	canvas.erase_line(event.position, true, size, opacity)


func left_click_drag(event):
	canvas.erase_line(event.position, false, size, opacity)


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


func _on_BrushSize_value_changed(value):
	size = value


func _on_BrushOpacity_value_changed(value):
	opacity = value


func _on_canvas_connected(canvas_node: Node):
	._on_canvas_connected(canvas_node)
	denoising_strenght.visible = q_img2img_module.is_main_board(canvas)
	use_modifiers.visible = q_img2img_module.is_main_board(canvas)
	q_img2img_button.visible = q_img2img_module.is_main_board(canvas)
	var ds = DiffusionServer
	ds.connect_feature(ds.FEATURE_IMG_TO_IMG, self, "_on_img2img_feature_toggled")


func _on_img2img_feature_toggled(enabled: bool):
	var should_show = q_img2img_module.is_main_board(canvas) and enabled
	denoising_strenght.visible = should_show
	use_modifiers.visible = should_show
	q_img2img_button.visible = should_show


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
	if brush_controller == null:
		return
	
	brush_controller.set_denoising_strenght(value)


func _on_UseModifiers_toggled(button_pressed):
	if brush_controller == null:
		return
	
	brush_controller.set_use_modifiers(button_pressed)


func _on_ResetImage_pressed():
	var main_controller
	var modifier: ModifierMode = null
	var layer: Layer2D = canvas.current_layer
	if layer == null:
		return
	
	if canvas is Canvas2D:
		main_controller = canvas.board_owner.controller_node
	if main_controller is Controller:
		modifier = main_controller.modifier
	
	var hidden_strokes: Dictionary = layer.hide_strokes()
	if not modifier is ModifierMode:
		# If we are talking about something that it is not a modifier (like the main canvas)
		# then we just clean the canvas instead
		var undoredo_act: Canvas2DUndoAction = canvas.undoredo_queue.add(layer)
		undoredo_act.add_undo_cue(Cue.new('', 'show_nodes').args(hidden_strokes.values()))
		undoredo_act.add_redo_cue(Cue.new('', 'hide_nodes').args(hidden_strokes.values()))
		return
	
	var restore_image = modifier.restore_image_data
	#restore_image.image.save_png("user://restore.png")
	if restore_image is ImageData:
		var previous_offsets = layer.get_offsets_data()
		layer.limits.size = restore_image.get_size()
		layer.limits.position = - layer.limits.size / 2
		layer.move_layer_offset = Vector2.ZERO
		layer.expand_layer_offset = Vector2.ZERO
		layer.refresh_limits()
		#canvas.fit_to_rect2(layer.limits)
		var new_offsets = layer.get_offsets_data()
		var texture_node = layer.draw_texture_at(restore_image.texture, Vector2.ZERO)
		var undoredo_act: Canvas2DUndoAction = canvas.add_texture_undoredo(texture_node, layer)
		undoredo_act.add_undo_cue(Cue.new('', 'show_nodes').args(hidden_strokes.values()))
		undoredo_act.add_undo_cue(Cue.new('', 'cue_set_offsets').args(previous_offsets))
		undoredo_act.add_undo_cue(Cue.new('', 'set_permanent_area_alpha').args([255]))
		undoredo_act.add_redo_cue(Cue.new('', 'hide_nodes').args(hidden_strokes.values()))
		undoredo_act.add_redo_cue(Cue.new('', 'cue_set_offsets').args(new_offsets))
		undoredo_act.add_redo_cue(Cue.new('', 'set_permanent_area_alpha').args([0]))
	else:
		var undoredo_act: Canvas2DUndoAction = canvas.undoredo_queue.add(layer)
		undoredo_act.add_undo_cue(Cue.new('', 'show_nodes').args(hidden_strokes.values()))
		undoredo_act.add_redo_cue(Cue.new('', 'hide_nodes').args(hidden_strokes.values()))
		
