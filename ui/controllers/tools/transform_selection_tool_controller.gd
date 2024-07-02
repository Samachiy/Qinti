extends ToolController

# KNOWNBUG
#	- This bug is not fixed because there's pending a minor reqork of how layers work
#		which will solve this problem (and a few others) by default, if there's too much demand
#		fix, it will be fixed sooner, if not, it will wait until migrating to Godot 4 to also
#		apply the new layer architecture as part of code maintenance
#	- Bug description: On transform tool, rotating and then expanding without resetting or 
#			applying changes, causes the layer to get cropped
#		There are (in theory) two ways to fix this:
#		- keep the unrotated_size and the current_size; on resizing, change the unrotated size and 
#				then add the angle offset, once that final size is calculated, apply it to the 
#				current_size. Also, if possible,rotate the transform frame rather than applying 
#				the current_size to it; apply/use the current size only on apply transform
#		- transform_area_button.gd > move_by(), the lock proportions makes it 
#				resize nicely, we have to add there an elif layer.rotation != 0 
#				that possibly uses get_fix_sign() inverted ( aka: - get_fixed_sign() ) 
#				to multiply by some angle shenanigans like in layer2d.gd > rotate_to()

const SNAP_SIZE = 8

# These two consts need to be in sync withe consts in transfrom_area.gd
# These are not applied to global consts due to being extramelly local to this case
const ROTATE_NAME = 'rotate'
const SCALE_NAME = 'scale'

onready var width = $Width
onready var height = $Height
onready var rotation = $Rotation

enum undoredo_types{
	NONE,
	MOVE,
	SCALE,
	ROTATE,
}

var active_button = null
var layer: Layer2D = null
var ongoing_action: Canvas2DUndoAction = null
var undoredo_type = undoredo_types.NONE
var is_proportion_locked: bool = false
var snap: bool = true
var movement_cache: Vector2 = Vector2.ZERO # intended for snapping
var original_limits: Rect2 = Rect2()

func reload_description(_cue: Cue = null):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "add").args([9]).opts({
		Consts.UI_CONTROL_LEFT_CLICK: Consts.HELP_DESC_MOVE_IMAGE,
	}).execute()


func select_tool():
	layer = canvas.get_selected_layer()
	if layer == null:
		return
	
	layer.set_lock_proportions(is_proportion_locked)
	visible = true
	active_button = null
	var e = layer.connect("proportions_changed", self, "_on_layer_proportions_changed")
	l.error(e, l.CONNECTION_FAILED)
	e = layer.connect("rotation_changed", self, "_on_layer_rotation_changed")
	l.error(e, l.CONNECTION_FAILED)
	layer.transform_frame.visible = true
	layer.show_interactables()
	layer.set_scale_on_expand(true)
	layer.set_lock_proportions(is_proportion_locked)
	original_limits = layer.limits
	layer.center_pivot()
	layer.remember_offsets()
	layer.prev_limit = layer.limits
	_on_layer_proportions_changed(layer.limits)
	canvas.temp_tool_undoredo = Canvas2DUndoQueue.new(canvas.UNDO_REDO_LIMIT)


func deselect_tool():
	if layer == null:
		return
	if layer.is_connected("proportions_changed", self, "_on_layer_proportions_changed"):
		layer.disconnect("proportions_changed", self, "_on_layer_proportions_changed")
	if layer.is_connected("rotation_changed", self, "_on_layer_rotation_changed"):
		layer.disconnect("rotation_changed", self, "_on_layer_rotation_changed")
	visible = false
	active_button = null
	layer.apply_scale_and_rotation()
	layer.restore_pivot()
	rotation.set_value(0)
	layer.set_scale_on_expand(false)
	if layer is GenerationArea2D:
		layer.hide_interactables()
	else:
		layer.transform_frame.visible = false
	layer = null
	canvas.temp_tool_undoredo = null


func _on_canvas_connected(canvas_node: Node):
	._on_canvas_connected(canvas_node)
# warning-ignore:return_value_discarded
	canvas_node.connect("layer_transform_button_pressed", self, 
			"_on_layer_transform_button_pressed")


func _on_layer_transform_button_pressed(button):
	if not is_visible_in_tree():
		return
	
	active_button = button
	active_button.activate()


func button_released(_event: InputEventMouseButton):
	if active_button != null:
		var aux = active_button
		active_button.deactivate()
		active_button = null
		aux.snap(SNAP_SIZE) 
		add_redo_action()
		undoredo_type = undoredo_types.NONE


func left_click(_event: InputEventMouseButton):
	if layer == null:
		return
	
	if snap:
		layer.snap(SNAP_SIZE)
	
	return true


func left_click_drag(event: InputEventMouseMotion):
	if layer == null:
		return
	
	if active_button == null:
		undoredo_type = undoredo_types.MOVE
		movement_cache += canvas.convert_movement(event.relative) 
		var move_amount
		var aux: Vector2 = Vector2.ZERO
		if snap:
			aux.x = fmod(movement_cache.x, SNAP_SIZE)
			aux.y = fmod(movement_cache.y, SNAP_SIZE)
			move_amount = movement_cache - aux
			movement_cache = aux
			layer.move_layer_by(move_amount)
		else:
			move_amount = movement_cache
			movement_cache = Vector2.ZERO
			layer.move_layer_by(move_amount)
	elif active_button.get("type") == SCALE_NAME:
		undoredo_type = undoredo_types.SCALE
		active_button.move_by(
				canvas.convert_position_change(event.relative),
				snap,
				SNAP_SIZE)
	elif active_button.get("type") == ROTATE_NAME:
		undoredo_type = undoredo_types.ROTATE
		active_button.rotate_by(
				canvas.convert_position_change(event.relative)
				)
	
	add_undo_action()


func add_undo_action(force: bool = false):
	if ongoing_action == null:
		ongoing_action = canvas.temp_tool_undoredo.add(layer)
	else:
		if not force:
			return
	
	match undoredo_type:
		undoredo_types.MOVE:
			ongoing_action.add_undo_cue(Cue.new("", "cue_set_limits").args([
					layer.limits]))
		undoredo_types.SCALE:
			ongoing_action.add_undo_cue(Cue.new("", "cue_expand_limits").args([
					layer.limits, true]))
		undoredo_types.ROTATE:
			ongoing_action.add_undo_cue(Cue.new("", "cue_rotate_to").args([
					layer.get_angle()]))
		undoredo_types.NONE:
			l.g("Can't add undo action, no undoredo type specified at: " + str(filename))


func add_redo_action():
	if ongoing_action == null:
		return
	
	match undoredo_type:
		undoredo_types.MOVE:
			ongoing_action.add_redo_cue(Cue.new("", "cue_set_limits").args([
					layer.limits]))
		undoredo_types.SCALE:
			ongoing_action.add_redo_cue(Cue.new("", "cue_expand_limits").args([
					layer.limits, true]))
		undoredo_types.ROTATE:
			ongoing_action.add_redo_cue(Cue.new("", "cue_rotate_to").args([
					layer.get_angle()]))
		undoredo_types.NONE:
			l.g("Can't add redo action, no undoredo type specified at: " + str(filename))


func _on_layer_proportions_changed(rect2: Rect2):
	if rect2 == null:
		return
	
	width.set_value(rect2.size.x, false) # false the value_changed signal won't be emitted
	height.set_value(rect2.size.y, false) # false the value_changed signal won't be emitted


func _on_layer_rotation_changed(angle: float):
	rotation.set_value(angle, false) # false the value_changed signal won't be emitted


func _on_Height_value_changed(value):
	if layer == null:
		return
	
	var rect2: Rect2 = layer.limits
	if is_proportion_locked:
		rect2.size.x *= value / rect2.size.y # scale according to proportion
		width.set_value(rect2.size.x, false) # false, the value_changed signal won't be emitted
	
	rect2.size.y = value
	layer.expand_limits(rect2, layer.get_scale_on_expand())


func _on_Width_value_changed(value):
	if layer == null:
		return
	
	var rect2: Rect2 = layer.limits
	if is_proportion_locked:
		rect2.size.y *= value / rect2.size.x # scale according to proportion
		height.set_value(rect2.size.y, false) # false, the value_changed signal won't be emitted
	
	rect2.size.x = value
	layer.expand_limits(rect2, layer.get_scale_on_expand())


func _on_Rotation_value_changed(value):
	if layer == null:
		return
	
	layer.rotate_to(value)


func get_width():
	if layer == null: 
		return 0
	else:
		return layer.limits.size.x


func get_height():
	if layer == null: 
		return 0
	else:
		return layer.limits.size.y


func reset():
	# We save the current state via cues in order to undo
	undoredo_type = undoredo_types.MOVE
	add_undo_action()
	undoredo_type = undoredo_types.SCALE
	add_undo_action()
	undoredo_type = undoredo_types.ROTATE
	add_undo_action()
	
	# We discard changes
	layer.rotate_to(0)
	layer.restore_offsets()
	layer.restore_pivot()
	layer.center_pivot()
	
	# We save the new state via queues in order to redo
	undoredo_type = undoredo_types.MOVE
	add_redo_action()
	undoredo_type = undoredo_types.SCALE
	add_redo_action()
	undoredo_type = undoredo_types.ROTATE
	add_redo_action()
	
	# We go back to no undoredo type since no interaction with canvas should be happening
	undoredo_type = undoredo_types.NONE


func _on_Reset_pressed():
	reset()


func _on_LockProportion_toggled(button_pressed):
	is_proportion_locked = button_pressed
	if layer is Layer2D:
		layer.set_lock_proportions(is_proportion_locked)


func _on_SnapToGrid_toggled(button_pressed):
	snap = button_pressed

