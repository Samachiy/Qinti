extends Panel

class_name Canvas2D

onready var camera = $ViewportContainer/Viewport/Camera2D
onready var layers = $ViewportContainer/Viewport/Layers
onready var display_viewport = $ViewportContainer/Viewport
onready var viewport_container = $ViewportContainer
onready var grid = $ViewportContainer/Viewport/Camera2D/Grid
onready var top_shadow = $Shadows/VBox/TopShadow
onready var right_shadow = $Shadows/RightShadow
onready var left_shadow = $Shadows/LeftShadow
onready var bottom_shadow = $Shadows/VBox/BottomShadow
onready var underlay = $ViewportContainer/Viewport/Camera2D/Underlay
onready var active_area_node = $Shadows/VBox/ActiveArea
onready var modifiers_overlay = $Shadows/VBox/ActiveArea/ModifiersOverlay
onready var gen_image_overlay = $Shadows/VBox/ActiveArea/GenAreaImageOverlay
onready var gen_mask_overlay = $Shadows/VBox/ActiveArea/GenAreaMaskOverlay
onready var lay = $OverunderlayModule
onready var pointer = $ViewportContainer/Viewport/Pointer
onready var message_area = $MessageArea
onready var preview = $PreviewThumbnail
onready var menu = $"%Menu"

const MOUSE_SPEED = 1
const UNDO_REDO_LIMIT = 4
const PREVIEW_SIZE = 70
const PREVIEW_MARGIN = 15
const MODIFIERS_UNDERLAY = 'u_mod'
const MODIFIERS_OVERLAY = 'o_mod'
const GEN_IMAGE_OVERLAY = 'o_genimg'
const GEN_MASK_OVERLAY = 'o_genmask'

enum{
	LEFT_CLICK_PRESS,
	RIGHT_CLICK_PRESS,
	MIDDLE_CLICK_PRESS,
	NO_PRESS
}

var layer_packed_scene = preload("res://ui/canvas/canvas_2d/layer2d.tscn")
var gen_area_packed_scene = preload("res://ui/canvas/canvas_2d/generation_area2d.tscn")

var mouse_status = NO_PRESS
var current_layer: Control = null setget set_current_layer
var layers_registry: Dictionary = {}
var undoredo_queue: Canvas2DUndoQueue = Canvas2DUndoQueue.new(UNDO_REDO_LIMIT)
var temp_tool_undoredo: Canvas2DUndoQueue = null
var display_area: Rect2 # the area that has to be displayed when resizing the GUI
var generation_area: GenerationArea2D = null
var shadow_inactive_area: bool = false
var active_area_proportions: Vector2 = Vector2.ZERO
var board_owner: Node = null

# warning-ignore:unused_signal
signal left_click(event)
signal left_click_drag(event)
# warning-ignore:unused_signal
signal right_click(event)
signal right_click_drag(event)
# warning-ignore:unused_signal
signal middle_click(event)
signal middle_click_drag(event)
signal scroll_up(event)
signal scroll_down(event)
# warning-ignore:unused_signal
signal mouse_button_released(event)
signal mouse_moved(event, is_inside)
signal mouse_exited_canvas()
signal layer_created(layer)
signal region_layer_created(layer)

signal zoom_changed(value)

# This signals are indeed used, but by the layers when a transfrom_button is pressed
# in other words, this signal is emitted by one of the layers but not the canvas 
# itself
# warning-ignore:unused_signal
signal layer_transform_button_pressed(button) 
# warning-ignore:unused_signal
signal layer_region_resize_button_pressed(button) 

func _ready():
	lay.set_lay(underlay, self, "active_area_proportions", MODIFIERS_UNDERLAY)
	lay.set_lay(modifiers_overlay, self, "active_area_proportions", MODIFIERS_OVERLAY)
	lay.set_lay(gen_image_overlay, self, "active_area_proportions", GEN_IMAGE_OVERLAY)
	lay.set_lay(gen_mask_overlay, self, "active_area_proportions", GEN_MASK_OVERLAY)
	gen_mask_overlay.modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
	UIOrganizer.add_to_theme_by_modulate_group(gen_mask_overlay, Consts.THEME_MODULATE_GROUP_STYLE)
	message_area.preview = preview
	preview.visible = false
	message_area.preview_size = PREVIEW_SIZE
	message_area.preview_margin = PREVIEW_MARGIN


# warning-ignore:unused_argument
func _process(delta):
	if is_visible_in_tree():
		if Input.is_action_just_pressed("ui_undo"):
			undo()
		elif Input.is_action_just_pressed("ui_redo"):
			redo()


# ACTIONS


func undo():
	if temp_tool_undoredo != null:
		temp_tool_undoredo.undo()
	else:
		undoredo_queue.undo()
	
	refresh_viewport()


func redo():
	if temp_tool_undoredo != null:
		temp_tool_undoredo.redo()
	else:
		undoredo_queue.redo()
	
	refresh_viewport()


func create_new_undoredo():
	undoredo_queue = Canvas2DUndoQueue.new(UNDO_REDO_LIMIT)
	return undoredo_queue


func convert_position(pos: Vector2):
	pos = pos - Vector2(display_viewport.size) / 2
	pos = pos * camera.zoom
	return pos + camera.position


func convert_back_position(pos: Vector2):
	pos = pos - camera.position 
	pos = pos / camera.zoom
	pos = pos + Vector2(display_viewport.size) / 2
	return pos


func convert_movement(relative_pos_from_prev):
	return relative_pos_from_prev * MOUSE_SPEED * camera.zoom.x


func convert_position_change(relative_pos_from_prev):
	return relative_pos_from_prev * MOUSE_SPEED


func add_texture_undoredo(texture_node: Node2D, layer_owner: Layer2D):
	# This is done this way because a sometimes the draw_texture_at doesn't 
	# requiere a undo action.
	# The draw_texture_at functions is also not here (in comparison with paint 
	# and erase) due to the same reason
	var undo_action: Canvas2DUndoAction = undoredo_queue.add(layer_owner)
	undo_action.register_node(texture_node)
	return undo_action


func paint_line(pos: Vector2, color: Color, new_line: bool, size: int = 10): 
	# opacity is in the color
	if current_layer == null:
		l.g("Can't paint line in null/non-existant layer")
		return
	
	pos = convert_position(pos)
	var new_line_node = current_layer.paint_line(pos, color, new_line, size)
	if new_line_node != null:
		var undo_action: Canvas2DUndoAction = undoredo_queue.add(current_layer)
		undo_action.register_node(new_line_node)


func erase_line(pos: Vector2, new_line: bool, size: int = 10, opacity: int = 255):
	if current_layer == null:
		l.g("Can't erase line in null/non-existant layer")
		return
	
	pos = convert_position(pos)
	var new_line_node = current_layer.erase_line(pos, new_line, size, opacity)
	if new_line_node != null:
		var undo_action: Canvas2DUndoAction = undoredo_queue.add(current_layer)
		undo_action.register_node(new_line_node)


func paint_mask_line(pos: Vector2, new_line: bool, size: int = 10, opacity: int = 255):
	if current_layer == null:
		l.g("Can't paint mask line in null/non-existant layer")
		return
	
	pos = convert_position(pos)
	var new_line_node = current_layer.paint_mask_line(pos, new_line, size, opacity)
	if new_line_node != null:
		var undo_action: Canvas2DUndoAction = undoredo_queue.add(current_layer)
		undo_action.register_node(new_line_node)


func erase_mask_line(pos: Vector2, new_line: bool, size: int = 10, opacity: int = 255):
	if current_layer == null:
		l.g("Can't erase mask line in null/non-existant layer")
		return
	
	pos = convert_position(pos)
	var new_line_node = current_layer.erase_mask_line(pos, new_line, size, opacity)
	if new_line_node != null:
		var undo_action: Canvas2DUndoAction = undoredo_queue.add(current_layer)
		undo_action.register_node(new_line_node)


func show_mask():
	if current_layer == null:
		l.g("Can't show mask in null/non-existant layer")
		return
	
	current_layer.show_mask()


func hide_mask():
	if current_layer == null:
		l.g("Can't hide mask in null/non-existant layer")
		return
	
	current_layer.hide_mask()


func hide_all_masks():
	for layer in layers.get_children():
		if layer is Layer2D:
			layer.hide_mask()
	
	if generation_area != null:
		generation_area.hide_mask()


func move_camera_by_mouse_motion(event: InputEventMouseMotion):
	var new_position = camera.position - convert_movement(event.relative)
	camera.set_position_with_grid(new_position)
	update_display_area()


func zoom_in(value: float = 0.1):
	set_zoom(camera.zoom.x - value)


func zoom_out(value: float = 0.1):
	set_zoom(camera.zoom.x + value)


func set_zoom(value: float = 0.1, update_display_area = true):
	if camera.set_zoom_with_grid(clamp(value, 0.2, 8)):
		emit_signal("zoom_changed", camera.current_zoom)
		if update_display_area:
			update_display_area()


func get_camera_data():
	return [camera.current_zoom, camera.position]


func set_camera_data(camera_data: Array):
	camera.position = camera_data[1]
	set_zoom(camera_data[0])


func add_generation_area():#fit_to_area: bool = true):
	var gen_area = gen_area_packed_scene.instance()
	gen_area.canvas = self
	display_viewport.add_child(gen_area)
	generation_area = gen_area
	var e = connect("layer_created", generation_area, "_on_layer_created")
	l.error(e, l.CONNECTION_FAILED)
	generation_area.send_bg_if_empty = true
	generation_area.connect_view_changed(preview, "set_preview_any_image_object")
	preview.visible = true
	preview.set_preview_dimensions(PREVIEW_SIZE, PREVIEW_MARGIN)
	display_viewport.move_child(pointer, display_viewport.get_child_count() - 1)


# LAYER MANAGEMENT


func add_layer(id: String = ''):
	var new_layer = layer_packed_scene.instance()
	new_layer.canvas = self
	layers.add_child(new_layer)
	if id.empty():
		id = new_layer.name
	
	layers_registry[id] = new_layer
	emit_signal("layer_created", new_layer)
	return id


func add_region_layer(id: String = ''):
	var new_layer = RegionLayer2D.new()
	new_layer.canvas = self
	layers.add_child(new_layer)
	if id.empty():
		id = new_layer.name
	
	layers_registry[id] = new_layer
	emit_signal("region_layer_created", new_layer)
	return id


func remove_all_layers():
	var layer
	for layer_id in layers_registry:
		layer = layers_registry.get(layer_id, null)
# warning-ignore:return_value_discarded
		remove_layer_object(layer)
	
	layers_registry.clear()


func remove_layer(id: String):
	var layer = layers_registry.get(id, null)
# warning-ignore:return_value_discarded
	layers_registry.erase(id)
	return remove_layer_object(layer)


func remove_layer_object(layer: Node) -> bool:
	if layer != null:
		layers.remove_child(layer)
		layer.queue_free()
		return true
	else:
		return false


func get_layer(layer_number: int):
	return layers.get_child(layer_number)


func select_layer(layer_id: String):
	var aux = layers_registry.get(layer_id)
	if aux != null:
		self.current_layer = aux
	
	return aux


func get_selected_layer():
	return current_layer


func set_current_layer(value):
	if value == current_layer:
		return
	
	if value is Layer2D:
		current_layer = value
	elif value is RegionLayer2D:
		current_layer = value
	else:
		l.g("Can't set layer2d, value is: " + str(value))


func get_all_layers():
	return layers.get_children()


# INPUT RAW PROCESSING

func process_mouse_click(event: InputEventMouseButton):
	var is_pressed = event.is_pressed()
	var button_index = event.get_button_index()
	if is_pressed:
		match button_index:
			BUTTON_LEFT:
				set_mouse_status(LEFT_CLICK_PRESS, "left_click", event)
			BUTTON_RIGHT:
				set_mouse_status(RIGHT_CLICK_PRESS, "right_click", event)
			BUTTON_MIDDLE:
				set_mouse_status(MIDDLE_CLICK_PRESS, "middle_click", event)
			BUTTON_WHEEL_UP:
				emit_signal("scroll_up", event)
			BUTTON_WHEEL_DOWN:
				emit_signal("scroll_down", event)
	else:
		#if button_index != MouseButton.MOUSE_BUTTON_WHEEL_UP \
		#and button_index != MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
		set_mouse_status(NO_PRESS, "mouse_button_released", event)


func set_mouse_status(status: int, signal_to_emit_on_change: String, event):
	if status != mouse_status:
		mouse_status = status
		emit_signal(signal_to_emit_on_change, event)


func process_mouse_movement(event: InputEventMouseMotion):
	match mouse_status:
		LEFT_CLICK_PRESS:
			emit_signal("left_click_drag", event)
		RIGHT_CLICK_PRESS:
			emit_signal("right_click_drag", event)
		MIDDLE_CLICK_PRESS:
			emit_signal("middle_click_drag", event)


func fit_to_rect2(rect2: Rect2):
	if rect2.size.x == 0 or rect2.size.y == 0:
		return
	
	var viewport_size = viewport_container.rect_size
	viewport_size.y -= message_area.get_y_displacement_amount()
	var proportion_diff = rect2.size / viewport_size # inner / outer
	var zoom
	if proportion_diff.y < proportion_diff.x:
		zoom = proportion_diff.x
	else:
		zoom = proportion_diff.y
	
	set_zoom(zoom, false)
	camera.position = rect2.get_center()
	camera.position.y += message_area.get_y_displacement_amount() / 2 * zoom


func update_display_area():
	var size: Vector2 = viewport_container.rect_size
	var pos: Vector2 = camera.position
	if shadow_inactive_area:
		size.x -= right_shadow.rect_size.x * 2
		size.y -= bottom_shadow.rect_size.y * 2
	
	size *= camera.zoom.x
	pos -= size / 2
	display_area = Rect2(pos, size)


func set_shadow_area(active_area: Vector2):
	if active_area == Vector2.ZERO:
		shadow_inactive_area = false
	else:
		shadow_inactive_area = true
	
	active_area_proportions = active_area


func set_shadow_area_cue(cue: Cue):
	# [active_area: Vector2]
	var active_area = cue.get_at(0, Vector2.ZERO)
	if active_area is Vector2:
		set_shadow_area(active_area)


func update_shadow_areas():
	if not shadow_inactive_area:
		return
	
	var size: Vector2 = viewport_container.rect_size
	var diff_proportions = active_area_proportions / size
	var scale_by # mult_by is also a good name
	if diff_proportions.x >= diff_proportions.y:
		scale_by = size.x / active_area_proportions.x
	else:
		scale_by = size.y / active_area_proportions.y
	
	var final_active_area_size: Vector2 = active_area_proportions * scale_by
	var shadows_size: Vector2 = size - final_active_area_size 
	top_shadow.rect_min_size.y = shadows_size.y / 2
	left_shadow.rect_min_size.x = shadows_size.x / 2
	right_shadow.rect_min_size.x = left_shadow.rect_min_size.x
	bottom_shadow.rect_min_size.y = top_shadow.rect_min_size.y


func get_unshadowed_area() -> Rect2:
	# The calculation is different from display area because in display area
	# we are trying to get the coordinates inside the 2d space whereas here
	# we are trying to get the coordinates inside the screenshot, which will always
	# be (0, 0) in the upper left corner of what is in the screen
	var size: Vector2 = viewport_container.rect_size
	var pos: Vector2 = size / 2
	if shadow_inactive_area:
		size.x -= right_shadow.rect_size.x * 2
		size.y -= bottom_shadow.rect_size.y * 2
	
	pos -= size / 2
	return Rect2(pos, size)


func get_displayed_image(area: Rect2 = Rect2()) -> Image:
	var screenshot: Image = display_viewport.get_texture().get_data()
	if not display_viewport.render_target_v_flip:
		screenshot.flip_y()
	
	if area != Rect2():
		screenshot = screenshot.get_rect(area)
	
	return screenshot


func get_active_image() -> Image:
	# The calculation is different from display_area because in display area
	# we are trying to get the coordinates inside the 2d space whereas here
	# we are trying to get the coordinates inside the screenshot, which will always
	# be (0, 0) in the upper left corner of what is in the screen
	var size: Vector2 = viewport_container.rect_size
	var pos: Vector2 = size / 2
	if shadow_inactive_area:
		size.x -= right_shadow.rect_size.x * 2
		size.y -= bottom_shadow.rect_size.y * 2
	
	# We are substracting the size without the shadows, not the original size, this will
	# ensure that the shadowed areas don't appear in the image
	pos -= size / 2
	return get_displayed_image(Rect2(pos, size))


func get_canvas_image(limits = null, add_gen_area: bool = true) -> Image:
	if not limits is Rect2:
		limits = get_canvas_limits(add_gen_area)
	
	var image = Image.new()
	image.create(limits.size.x, limits.size.y, false, Image.FORMAT_RGBA8)
	var aux_image
	var aux_pos
	var aux_size
	var blend_layers = layers.get_children()
	if add_gen_area and generation_area is GenerationArea2D:
		if generation_area.current_image_data != null:
			blend_layers.append(generation_area)
	
	for layer in blend_layers:
		if layer is Layer2D:
			aux_image = layer.get_visible_image()
			aux_pos = layer.limits.position - limits.position
			aux_size = layer.limits.size
			image.blend_rect(aux_image, Rect2(Vector2.ZERO, aux_size), aux_pos)
	
	return image


func get_canvas_mask(limits = null) -> Image:
	if not limits is Rect2:
		limits = get_canvas_limits(false)
	
	var image = Image.new()
	image.create(limits.size.x, limits.size.y, false, Image.FORMAT_RGBA8)
	var aux_image
	var aux_pos
	for layer in layers.get_children():
		if layer is Layer2D:
			aux_image = layer.get_visible_mask()
			aux_pos = layer.limits.position - limits.position
			image.blend_rect(aux_image, Rect2(Vector2.ZERO, layer.limits.size), aux_pos)
	
	return image


func get_canvas_limits(add_gen_area: bool) -> Rect2:
	var limits = null
	var blend_layers = layers.get_children()
	if add_gen_area and generation_area is GenerationArea2D:
		if generation_area.current_image_data != null:
			blend_layers.append(generation_area)
	for layer in blend_layers:
		if not layer is Layer2D:
			continue
		
		if limits is Rect2:
			limits = limits.merge(layer.limits)
		else:
			limits = layer.limits
	
	if limits is Rect2:
		return limits
	else:
		return Rect2(Vector2.ZERO, Vector2.ZERO)


func get_save_data() -> Dictionary:
	var layer_obj
	var result_data = {}
	for layer_key in layers_registry:
		layer_obj = layers_registry[layer_key]
		if layer_obj is Layer2D:
			result_data[layer_key] = layer_obj.get_save_data()
	
	return result_data


func add_layers_data(layers_data: Dictionary):
	var layer
	for layer_key in layers_data:
		add_layer(layer_key)
		layer = layers_registry.get(layer_key)
		layer.set_save_data(layers_data[layer_key])


func _on_gui_input(event):
	if not event is InputEventMouse:
		return
	
	var is_inside = viewport_container.get_global_rect().has_point(get_global_mouse_position())
	if event is InputEventMouseButton:
		if is_inside or mouse_status != NO_PRESS:
			process_mouse_click(event)
	elif event is InputEventMouseMotion:
		if is_inside or mouse_status != NO_PRESS:
			process_mouse_movement(event)
			emit_signal("mouse_moved", event, is_inside)


func _on_resized():
	if camera != null:
		fit_to_rect2(display_area)
		update_shadow_areas()


func _on_MessageArea_message_area_displayed():
	_on_resized()


func _on_MessageArea_message_area_hiding():
	update_display_area()


func refresh_viewport():
	# Function intended to foce viewport to update
	# VIewports in godot can't be manually updated, however, does
	# works but IN THE CONTEXT this function is currently used.
	# Please use it while keeping that in mind
	camera.position.x += 1
	yield(VisualServer, "frame_post_draw")
	camera.position.x -= 1



func _on_ViewportContainer_mouse_exited():
	emit_signal("mouse_exited_canvas")
