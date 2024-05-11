extends ToolController

const SNAP_SIZE = 8

var region: RegionArea2D = null
var active_button = null
var snap: bool = true
var movement_cache: Vector2 = Vector2.ZERO # intended for snapping



func select_tool():
	visible = true
	active_button = null
	
	var selected_region = controller_owner.get_current_region()
	if not selected_region is RegionArea2D:
		return
	
	region = selected_region
	region.show_interactables()


func deselect_tool():
	if region is RegionArea2D:
		region.hide_interactables()
		region = null
	
	visible = false
	active_button = null


func button_released(_event: InputEventMouseButton):
	if active_button != null:
		var aux = active_button
		active_button.active = false
		active_button = null
		aux.snap(SNAP_SIZE) 


#func right_click(event: InputEventMouseButton):
#	var pos = canvas.convert_position(event.position)
#	if region is RegionArea2D:
#		region.limits.position = pos
#		region.refresh_region()
#	return true


func left_click(_event: InputEventMouseButton):
	if region == null:
		return
	
	if snap:
		region.snap(SNAP_SIZE)
	
	return true


func left_click_drag(event: InputEventMouseMotion):
	if active_button != null:
		active_button.move_by(
				canvas.convert_position_change(event.relative),
				snap,
				SNAP_SIZE)
	else:
		movement_cache += canvas.convert_movement(event.relative) 
		var move_amount
		var aux: Vector2 = Vector2.ZERO
		if snap:
			aux.x = fmod(movement_cache.x, SNAP_SIZE)
			aux.y = fmod(movement_cache.y, SNAP_SIZE)
			move_amount = movement_cache - aux
			movement_cache = aux
			move_region(move_amount)
		else:
			move_amount = movement_cache
			movement_cache = Vector2.ZERO
			move_region(move_amount)


func move_region(move_amount: Vector2):
	if region is RegionArea2D:
		region.limits.position += move_amount
		region.refresh_region()



func _on_canvas_connected(canvas_node: Node):
	._on_canvas_connected(canvas_node)
# warning-ignore:return_value_discarded
	canvas_node.connect("layer_region_resize_button_pressed", self, 
			"_on_layer_region_resize_button_pressed")


func _on_layer_region_resize_button_pressed(button):
	if not is_visible_in_tree():
		return
	
	active_button = button
	active_button.activate()


func focus_region(region_node):
	region = region_node
	if region_node is RegionArea2D:
		region_node.modulate.a = 1
		region_node.show_interactables()


func unfocus_region(region_node):
	if region_node is RegionArea2D:
		region_node.modulate.a = 0.5
		region_node.hide_interactables()
