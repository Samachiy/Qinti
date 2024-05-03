extends ToolController

const SNAP_SIZE = 8

var layer: Control = null
var active_button = null
var snap: bool = true
var latest_region = null


func select_tool():
	visible = true
	active_button = null
	
	layer = canvas.get_selected_layer()
	if not layer is RegionLayer2D:
		l.g("Selected layer is not region layer on add region tool.")
		return
	


func deselect_tool():
	if not layer is RegionLayer2D:
		l.g("Selected layer is not region layer on add region tool.")
		return
	
	visible = false
	active_button = null
	layer = null


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



func button_released(_event: InputEventMouseButton):
	if active_button != null:
		active_button.deactivate()
		active_button.snap(SNAP_SIZE) 
		active_button = null
		controller_owner.add_missing_regions()
		if latest_region is RegionArea2D:
			controller_owner.select_region(latest_region)
			latest_region = null
		#add_redo_action()


func left_click(event: InputEventMouseButton):
	if not layer is RegionLayer2D:
		l.g("Selected layer is not region layer on add region tool.")
		return
	
	var pos = event.position
	pos = canvas.convert_position(pos)
	var region = layer.create_region(pos)
	region.hide_interactables()
	if region is RegionArea2D:
		region.bottom_right._on_button_down()
		region.snap(SNAP_SIZE)
		latest_region = region
	return true


func left_click_drag(event: InputEventMouseMotion):
	if active_button != null:
		active_button.move_by(
				canvas.convert_position_change(event.relative),
				snap,
				SNAP_SIZE)


func focus_region(region_node):
	if region_node is RegionArea2D:
		region_node.modulate.a = 1
		region_node.hide_interactables()


func unfocus_region(region_node):
	if region_node is RegionArea2D:
		region_node.modulate.a = 0.5
		region_node.hide_interactables()
