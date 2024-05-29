extends Control

class_name Layer2D

# When the viewport is resized, generally it will flicker, so we update the size
# in chunks, so that the flicker only happens sometimes
const CHUNK_SIZE = 700

const MAX_SCALE = 20
const MIN_SCALE = 0.1

const SAVE_LAYER = 0
const SAVE_MASK = 1
const SAVE_LIMITS = 2

# The offset is meant for when we have to expand the drawing limits to the left 
# or upwards. since the top-left corner is the position, you expand it not only 
# by changing the size, but the position too, this will put the image out
# of place, thus why the offset
onready var offset_area = $Display/Viewport/Offset
onready var pivot_area = $Display/Viewport/Offset/Pivot
onready var permanent_area = $Display/Viewport/Offset/Pivot/Permanent
onready var display_viewport = $Display/Viewport
onready var display = $Display

onready var offset_mask_area = $Mask/Viewport/Offset
onready var pivot_mask_area = $Mask/Viewport/Offset/Pivot
onready var permanent_mask_area = $Mask/Viewport/Offset/Pivot/Permanent
onready var mask_viewport = $Mask/Viewport
onready var mask = $Mask

onready var transform_frame = $TransformFrame

signal layer_moved(limits)
signal layer_edited()
signal proportions_changed(limits)
signal rotation_changed(angle)

export var clip_content: bool = true

var last_normal_line: BrushLine2D = null
var last_mask_line: BrushLine2D = null
var paint_material
var erase_material
var limits: Rect2 = Rect2(rect_position, rect_size)
var has_max_size: bool = false
var max_size: Rect2 setget set_max_size
var move_layer_offset: Vector2 = Vector2.ZERO
var expand_layer_offset: Vector2 = Vector2.ZERO
var canvas = null

var prev_limit: Rect2
var prev_scale: Vector2 = Vector2.ONE
var scale_counter: Vector2 = Vector2.ONE
var saved_offset_data: Array = [] # [limits: rect2, move_offset: vect2, expand_offset: vect2]
var default_texture_material = preload('res://ui/materials/layer_texture_material.tres')
var _save_data: Dictionary = {}


func _ready():
	display.texture = display_viewport.get_texture()
	display.texture.flags = Texture.FLAG_FILTER
	if clip_content:
		display.expand = true
		display.stretch_mode = TextureRect.STRETCH_KEEP
	mask.texture = mask_viewport.get_texture()
	mask.texture.flags = Texture.FLAG_FILTER
	if clip_content:
		mask.expand = true
		mask.stretch_mode = TextureRect.STRETCH_KEEP
	transform_frame.visible = false
	#connect("resized", self, "_on_resized")
	paint_material = CanvasItemMaterial.new()
	paint_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	erase_material = CanvasItemMaterial.new()
	erase_material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
	transform_frame.modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
	UIOrganizer.add_to_theme_by_modulate_group(transform_frame, Consts.THEME_MODULATE_GROUP_STYLE)
	mask.modulate.a8 = Consts.ACCENT_GLASS_HOVER_A
	UIOrganizer.add_to_theme_by_modulate_group(mask, Consts.THEME_MODULATE_GROUP_STYLE)
	refresh_viewport()


func draw_texture_at(texture: Texture, pos: Vector2, centered: bool = true, 
texture_sublayer: Sprite = null, texture_material: Material = null):
	var size = texture.get_size()
	if texture_sublayer == null:
		texture_sublayer = Sprite.new()
		pivot_area.add_child(texture_sublayer)
	texture_sublayer.centered = false
	if centered:
		pos -= size/2
	texture_sublayer.texture = texture
	# We apply the position on offset rather than position because when scaling
	# the position will be used as pivot point. To achieve a consistent scaling
	# all the nodes in the layer should be at the position (0, 0)
	texture_sublayer.offset = pos - get_offset()
	texture_sublayer.position = Vector2.ZERO
	if texture_material != null:
		texture_sublayer.material = texture_material
	else: 
		texture_sublayer.material = default_texture_material
	if not has_max_size:
		limits = limits.merge(Rect2(pos, size))
		refresh_size_with(limits, true)
		call_deferred("refresh_size_with", limits, true)
	
	emit_signal("layer_edited")
	refresh_viewport()
	return texture_sublayer


func paint_line(pos: Vector2, color: Color, new_line: bool, size: int = 10):
	# returns the newly created line 2d node if created, if not will return null
	var created_line = null
	if new_line or last_normal_line == null:
		last_normal_line = BrushLine2D.new()
		last_normal_line.position = Vector2.ZERO
		last_normal_line.material = paint_material
		last_normal_line.default_color = color
		last_normal_line.modulate.a = color.a
		last_normal_line.width = size
		pivot_area.add_child(last_normal_line)
		created_line = last_normal_line
	
	last_normal_line.add_point(pos - get_offset())
	if not has_max_size:
# warning-ignore:narrowing_conversion
# warning-ignore:narrowing_conversion
		refresh_size_with(limits.merge(point_to_rect2(pos, size)))
	
	emit_signal("layer_edited")
	return created_line


func erase_line(pos: Vector2, new_line: bool, size: int = 10, opacity: int = 255):
	var created_line = null
	if new_line or last_normal_line == null:
		last_normal_line = BrushLine2D.new()
		last_normal_line.default_color = Color(0, 0, 0, 1)
		last_normal_line.default_color.a8 = opacity
		last_normal_line.modulate.a8 = opacity
		last_normal_line.material = erase_material
		last_normal_line.width = size
		pivot_area.add_child(last_normal_line)
		created_line = last_normal_line
	
	last_normal_line.add_point(pos - get_offset())
	emit_signal("layer_edited")
	return created_line


func paint_mask_line(pos: Vector2, new_line: bool, size: int = 10, opacity: int = 255):
	# returns the newly created line 2d node if created, if not will return null
	var created_line = null
	if new_line or last_mask_line == null:
		last_mask_line = BrushLine2D.new()
		last_mask_line.material = paint_material
		last_mask_line.default_color = Color.white
		last_mask_line.default_color.a8 = opacity
		last_mask_line.width = size
		pivot_mask_area.add_child(last_mask_line)
		created_line = last_mask_line
	
	last_mask_line.add_point(pos - get_offset())
	
	return created_line


func erase_mask_line(pos: Vector2, new_line: bool, size: int = 10, opacity: int = 255):
	var created_line = null
	if new_line or last_mask_line == null:
		last_mask_line = BrushLine2D.new()
		last_mask_line.default_color = Color.white
		last_mask_line.default_color.a8 = opacity
		last_mask_line.material = erase_material
		last_mask_line.width = size
		pivot_mask_area.add_child(last_mask_line)
		created_line = last_mask_line
	
	last_mask_line.add_point(pos - get_offset())
	
	return created_line


func snap(amount: int):
	# Returns how much the image was moved when snapping
	var extra_x = fmod(limits.position.x, amount)
	var extra_y = fmod(limits.position.y, amount)
	var extra_amount = Vector2(-extra_x, -extra_y)
	move_layer_by(extra_amount)
#	limits.position.x = int(limits.position.x) - extra_x
#	limits.position.y = int(limits.position.y) - extra_y
	return extra_amount


func move_layer_by(amount: Vector2):
	move_layer_offset += amount
	limits.position += amount
	emit_signal("layer_moved", limits)
	refresh_limits()


func refresh_size_with(possible_new_size: Rect2, force: bool = false):
	if limits == possible_new_size and not force:
		return
	
	limits = possible_new_size
	refresh_limits()


func refresh_limits():
	canvas.display_viewport.set_update_mode(Viewport.UPDATE_DISABLED)
	set_layer_size(limits.size)
	transform_frame.rect_size = limits.size
	transform_frame.rect_position = limits.position
	offset_area.position = -limits.position + get_offset()
	offset_mask_area.position = offset_area.position
	display.rect_position = limits.position
	mask.rect_position = display.rect_position
	permanent_area.set_size_as(display_viewport.size)
	permanent_mask_area.set_size_as(display_viewport.size)
	permanent_area.set_position_as(limits.position, get_offset())
	permanent_mask_area.set_position_as(limits.position, get_offset())
	yield(VisualServer, "frame_pre_draw")
	yield(VisualServer, "frame_pre_draw")
	canvas.display_viewport.set_update_mode(Viewport.UPDATE_ALWAYS)


func set_layer_size(size: Vector2):
	# The following two lines allows to only scale in chunks 
	# and only increase the size, not reduce it.
	size.x = max(ceil(size.x / CHUNK_SIZE) * CHUNK_SIZE, display_viewport.size.x)
	size.y = max(ceil(size.y / CHUNK_SIZE) * CHUNK_SIZE, display_viewport.size.y)
	if size == display.rect_size:
		return
	
	if clip_content:
		display.rect_size = limits.size
		mask.rect_size = limits.size
		if not display.rect_size.is_equal_approx(limits.size):
			l.g("Resizing of layer failed with sizes '" + str(display.rect_size) + 
			str(size) + "'at: " + get_path())
	else:
		display.rect_size = size
		mask.rect_size = size
		if not display.rect_size.is_equal_approx(size):
			l.g("Resizing of layer failed with sizes '" + str(display.rect_size) + 
			str(size) + "'at: " + get_path())
	
	if size == display_viewport.size:
		return
	
	# This causes the distortion of image whne expanding stuff
	display_viewport.size = size
	mask_viewport.size = size


func point_to_rect2(position: Vector2, radius: int):
	position.x -= radius
	position.y -= radius
	radius *= 2
	return Rect2(position, Vector2(radius, radius))


func set_max_size(new_max_size: Rect2):
	has_max_size = true
	refresh_size_with(new_max_size, true)


func _on_top_limit_changed_by(new_value: float, scale: bool):
	var diff = new_value #rect_position.y - new_value
	var old_limits = limits
	var apply = true
	limits = limits.grow_individual(0, diff, 0, 0)
	if scale:
		apply = scale_by(old_limits.size, limits.size)
	
	if apply:
		if scale:
			expand_layer_offset -= Vector2(0, diff/2)
	else:
		# we undo the changes here
		limits = limits.grow_individual(0, -diff, 0, 0)
	
	# This signal will update the slider according to limits
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_limits()


func _on_bottom_limit_changed_by(new_value: float, scale: bool):
	var diff = new_value #rect_position.x + rect_size.x - new_value
	var old_limits = limits
	var apply = true
	limits = limits.grow_individual(0, 0, 0, diff)
	if scale:
		apply = scale_by(old_limits.size, limits.size)
	
	if apply:
		if scale:
			expand_layer_offset += Vector2(0, diff/2)
	else:
		# we undo the changes here
		limits = limits.grow_individual(0, 0, 0, -diff)
	
	# This signal will update the slider according to limits
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_limits()


func _on_right_limit_changed_by(new_value: float, scale: bool):
	var diff = new_value #rect_position.x + rect_size.x - new_value
	var old_limits = limits
	var apply = true
	limits = limits.grow_individual(0, 0, diff, 0)
	if scale:
		apply = scale_by(old_limits.size, limits.size)
	
	if apply:
		if scale:
			expand_layer_offset += Vector2(diff/2, 0)
	else:
		# we undo the changes here
		limits = limits.grow_individual(0, 0, -diff, 0)
	
	# This signal will update the slider according to limits
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_limits()


func _on_left_limit_changed_by(new_value: float, scale: bool):
	var diff = new_value #rect_position.x - new_value
	var old_limits = limits
	var apply = true
	limits = limits.grow_individual(diff, 0, 0, 0)
	if scale:
		apply = scale_by(old_limits.size, limits.size)
	
	if apply:
		if scale:
			expand_layer_offset -= Vector2(diff/2, 0)
	else:
		# we undo the changes here
		limits = limits.grow_individual(-diff, 0, 0, 0)
	
	# This signal will update the slider according to limits
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_limits()


func expand_limits(rect2: Rect2, scale: bool):
	var diff: Vector2 = rect2.size - limits.size
	_on_right_limit_changed_by(diff.x, scale)
	_on_bottom_limit_changed_by(diff.y, scale)


func cue_expand_limits(cue: Cue):
	var rect2 = cue.get_at(0, null)
	var scale = cue.bool_at(1, transform_frame.scale_on_expand)
	if rect2 == null:
		return
	expand_limits(rect2, scale)


func cue_set_limits(cue: Cue):
	var rect2 = cue.get_at(0, null)
	if not rect2 is Rect2:
		return
	
	limits = rect2
	refresh_limits()


func scale_by(prev_size: Vector2, new_size: Vector2):
	var new_scale_by: Vector2 = new_size / prev_size
	if not can_scale(new_scale_by):
		return false
	
	scale_counter *= new_scale_by
	pivot_area.scale *= new_scale_by
	pivot_mask_area.scale *= new_scale_by
	return true


func apply_scale_and_rotation(extra_hidden_strokes: Dictionary = {}, 
extra_remove_hidden: Array = []):
	if pivot_area.scale == Vector2.ONE and pivot_area.rotation_degrees == 0:
		return
	
	var image_texture = ImageTexture.new()
	var screenshoot = get_image(Rect2(Vector2.ZERO, limits.size))
	image_texture.create_from_image(screenshoot)
	var texture_node = draw_texture_at(image_texture, limits.position, false)
	var hidden_strokes: Dictionary = hide_strokes() # this needs to go after screenshot
	texture_node.visible = true # Previous line hid this
	
	hidden_strokes.merge(extra_hidden_strokes)
	for child in extra_remove_hidden:
# warning-ignore:return_value_discarded
		hidden_strokes.erase(child)
# warning-ignore:return_value_discarded
	hidden_strokes.erase(texture_node) # This node really should not be hidden along the others
	
	var undoredo_act: Canvas2DUndoAction = canvas.add_texture_undoredo(texture_node, self)
	undoredo_act.add_undo_cue(Cue.new('', 'show_nodes').args(hidden_strokes.values()))
	undoredo_act.add_undo_cue(Cue.new('', 'cue_set_offsets').args(saved_offset_data))
	undoredo_act.add_undo_cue(Cue.new('', 'set_permanent_area_alpha').args([255]))
	undoredo_act.add_redo_cue(Cue.new('', 'hide_nodes').args(hidden_strokes.values()))
	undoredo_act.add_redo_cue(Cue.new('', 'cue_set_offsets').args(get_offsets_data()))
	undoredo_act.add_redo_cue(Cue.new('', 'set_permanent_area_alpha').args([0]))


func can_scale(scale_by: Vector2):
	var target_scale = permanent_area.scale * scale_by
	if target_scale.x >= MIN_SCALE and target_scale.x <= MAX_SCALE:
		if target_scale.y >= MIN_SCALE and target_scale.y <= MAX_SCALE:
			return true
	
	return false


func rotate_to(angle: float):
	# W' = W |cos Θ| + H |sin Θ|, H' = W |sin Θ| + H |cos Θ|. 
	# Θ Are radians
	# To change from radians to degrees, you need to multiply the number of 
	# radians by 180/π
	# a = r * 180/p
	# r = a * p / 180
	var radian = angle * PI / 180
	var base_lim = prev_limit.size * pivot_area.scale
	var w = base_lim.x * abs(cos(radian)) + base_lim.y * abs(sin(radian))
	var h = base_lim.x * abs(sin(radian)) + base_lim.y * abs(cos(radian))
	var size_dif: Vector2 = Vector2(w, h) - limits.size
	size_dif /= 2 # divided by two so as to add half and half to left and right, top and down
	limits = limits.grow_individual(size_dif.x, size_dif.y, size_dif.x, size_dif.y)
	pivot_area.rotation_degrees = angle
	pivot_mask_area.rotation_degrees = angle
	emit_signal("rotation_changed", angle)
	transform_frame.move_rotation_indicator(angle)
	refresh_limits()


func cue_rotate_to(cue: Cue):
	var angle = cue.float_at(0, 0)
	rotate_to(angle)


func get_angle():
	return pivot_area.rotation_degrees


func center_pivot():
	var center = limits.get_center() - get_offset()
	
	for child in pivot_area.get_children():
		if child is Node2D:
			child.position = -center
	pivot_area.position = center
	
	for child in pivot_mask_area.get_children():
		if child is Node2D:
			child.position = -center
	pivot_mask_area.position = center


func restore_pivot():
	for child in pivot_area.get_children():
		if child is Node2D:
			# We move the child back to place due to the effects of center_pivot()
			child.position = Vector2.ZERO
	pivot_area.position = Vector2.ZERO
	pivot_area.scale = Vector2.ONE
	
	for child in pivot_mask_area.get_children():
		if child is Node2D:
			# We move the child back to place due to the effects of center_pivot()
			child.position = Vector2.ZERO
	pivot_mask_area.position = Vector2.ZERO
	pivot_mask_area.scale = Vector2.ONE


func remember_offsets():
	# [limits: rect2, move_offset: vect2, expand_offset: vect2]
	saved_offset_data = get_offsets_data()


func restore_offsets():
	if saved_offset_data.empty():
		return
	
	limits = saved_offset_data[0]
	move_layer_offset = saved_offset_data[1]
	expand_layer_offset = saved_offset_data[2]
	refresh_limits()


func get_offsets_data():
	return [
		limits,
		move_layer_offset,
		expand_layer_offset,
	]


func cue_set_offsets(cue: Cue):
	var offset_data = cue._arguments
	if offset_data.empty():
		return
	
	limits = offset_data[0]
	move_layer_offset = offset_data[1]
	expand_layer_offset = offset_data[2]
	refresh_limits()


func activate_transfrom_button(button: Control):
	if canvas == null:
		return
	
	canvas.emit_signal("layer_transform_button_pressed", button)
	scale_counter = Vector2.ONE


func deativate_transfrom_button(_button: Control):
	if canvas == null:
		return
	
	prev_scale = scale_counter # this is do that we can divide the prev_scale to restore it's shape
	# add undo/redo action


func refresh_viewport():
	# Function intended to foce viewport to update
	# VIewports in godot can't be manually updated, however, for whatever reason this
	# works IN THE CONTEXT this function is currently used.
	# Please use it while keeping that in mind
	display.rect_size.x += 1
	display.rect_size.x -= 1
	rect_size.x += 1
	rect_size.x -= 1
	mask.rect_size.x += 1
	mask.rect_size.x -= 1


func move_to_permanent(node: Node):
	if node is Sprite:
		pass
	if node.get_parent() == pivot_area:
		pivot_area.remove_child(node)
		permanent_area.add_node(node)
	elif node.get_parent() == pivot_mask_area:
		pivot_mask_area.remove_child(node)
		permanent_mask_area.add_node(node)


func set_layer_material(material_shader: ShaderMaterial):
	display.material = material_shader
	mask.material = material_shader


func get_image(area: Rect2 = Rect2()) -> Image:
	var screenshot: Image = display_viewport.get_texture().get_data()
	if not display_viewport.render_target_v_flip:
		screenshot.flip_y()
	if area != Rect2():
		screenshot = screenshot.get_rect(area)
	
	return screenshot


func get_visible_image() -> Image:
	return get_image(Rect2(Vector2.ZERO, limits.size))


func get_mask(area: Rect2 = Rect2()) -> Image:
	var screenshot: Image = mask_viewport.get_texture().get_data()
	if not mask_viewport.render_target_v_flip:
		screenshot.flip_y()
	
	if area != Rect2():
		screenshot = screenshot.get_rect(area)
	
	return screenshot


func get_visible_mask() -> Image:
	return get_mask(Rect2(Vector2.ZERO, limits.size))


func get_offset() -> Vector2:
	return move_layer_offset + expand_layer_offset


func clear_image():
	for child in pivot_area.get_children():
		if child == permanent_area:
			# We set the modulate to 0 so that the viewport keeps being updated
			permanent_area.modulate.a8 = 0
		elif child is Node2D:
			child.visible = false
	
	for child in permanent_area.offset_node.get_children():
		if child is Node2D:
			child.visible = false


func clear_mask():
	for child in pivot_mask_area.get_children():
		if child == permanent_mask_area:
			# We set the modulate to 0 so that the viewport keeps being updated
			permanent_mask_area.modulate.a8 = 0
		elif child is Node2D:
			child.visible = false
	
	for child in permanent_mask_area.offset_node.get_children():
		if child is Node2D:
			child.visible = false


func consolidate():
	_save_data[SAVE_LAYER] = get_image()
	_save_data[SAVE_MASK] = get_mask()
	permanent_area.consolidate()
	permanent_mask_area.consolidate()


func get_save_data() -> Dictionary:
	var layer_image = _save_data.get(SAVE_LAYER, null)
	var layer_mask = _save_data.get(SAVE_MASK, null)
	var result_data = {}
	if layer_image is Image:
		result_data[SAVE_LAYER] = ImageProcessor.image_to_base64(layer_image)
	if layer_mask is Image:
		if not layer_mask.is_invisible():
			result_data[SAVE_MASK] = ImageProcessor.image_to_base64(layer_mask)
	
	result_data[SAVE_LIMITS] = limits
	return result_data
 

func set_save_data(data: Dictionary):
	var image_base64 = data.get(SAVE_LAYER, '')
	var new_limits = data.get(SAVE_LIMITS, limits)
	limits = new_limits
	refresh_limits()
	var image_texture = ImageTexture.new()
	
	if image_base64 is String and not image_base64.empty():
		image_texture.create_from_image(ImageProcessor.png_base64_to_image(image_base64))
		draw_texture_at(image_texture, limits.position, false)


func is_empty(exception_nodes: Array = []):
	# Empty here is treated as the node being invisible because we still need 
	# them there in case of an undo. There's an exception in the permanent area
	# but that is handled by it's own is_empty() function
	var empty: bool = permanent_area.is_empty()
	for child in pivot_area.get_children():
		if not empty:
			break
		
		if child in exception_nodes:
			continue
		
		if child == permanent_area:
			continue
		
		if child is Node2D:
			empty = not child.visible
	
	return empty


func hide_strokes():
	var hidden_strokes = {}
	for child in pivot_area.get_children():
		if child.visible == true:
			hidden_strokes[child] = child
	
	for child in pivot_mask_area.get_children():
		if child.visible == true:
			hidden_strokes[child] = child
	
	for child in permanent_area.offset_node.get_children():
		if child.visible == true:
			hidden_strokes[child] = child
	
	for child in permanent_mask_area.offset_node.get_children():
		if child.visible == true:
			hidden_strokes[child] = child 
	
	clear_image()
	clear_mask()
	return hidden_strokes


func set_permanent_area_alpha(cue: Cue = null):
	var alpha = cue.int_at(0, 255)
	permanent_area.modulate.a8 = alpha
	permanent_mask_area.modulate.a8 = alpha


func show_nodes(cue: Cue):
	# [ node1, node2, node3, ... ]
	for node in cue._arguments:
		if not is_instance_valid(node):
			continue
		
		var has_visibility = node is Node2D or node is Control
		if not has_visibility:
			continue
		
		# We previously set the modulate to 0 so that the viewport keeps being updated
		if node == permanent_area or node == permanent_mask_area:
			node.modulate.a8 = 255
			continue
		
#		var is_permanent = permanent_area.is_a_parent_of(node) or permanent_mask_area.is_a_parent_of(node)
#		if not is_permanent:
		node.visible = true


func hide_nodes(cue: Cue):
	# [ node1, node2, node3, ... ]
	for node in cue._arguments:
		if not is_instance_valid(node):
			continue
		
		var has_visibility = node is Node2D or node is Control
		if not has_visibility:
			continue
		
		# We set the modulate to 0 so that the viewport keeps being updated
		if node == permanent_area or node == permanent_mask_area:
			node.modulate.a8 = 0
			continue
		
#		var is_permanent = permanent_area.is_a_parent_of(node) or permanent_mask_area.is_a_parent_of(node)
#		if not is_permanent:
		node.visible = false


func hide_interactables():
	transform_frame.hide_interactables()


func show_interactables():
	transform_frame.show_interactables()


func set_scale_on_expand(value: bool):
	transform_frame.scale_on_expand = value


func get_scale_on_expand():
	return transform_frame.scale_on_expand


func set_lock_proportions(value: bool):
	transform_frame.lock_proportions = value


func get_lock_proportions():
	return transform_frame.lock_proportions


func show_mask():
	mask.visible = true


func hide_mask():
	mask.visible = false
