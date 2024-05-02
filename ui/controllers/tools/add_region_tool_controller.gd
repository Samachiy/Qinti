extends ToolController

const SNAP_SIZE = 8

var layer: Control = null
var active_button = null
var snap: bool = true




func select_tool():
	layer = canvas.get_selected_layer()
	if not layer is RegionLayer2D:
		l.g("Selected layer is not region layer on add region tool.")
		return
	
	visible = true
	active_button = null
	layer.show_interactables()


func deselect_tool():
	if not layer is RegionLayer2D:
		l.g("Selected layer is not region layer on add region tool.")
		return
	
	if layer.is_connected("proportions_changed", self, "_on_layer_proportions_changed"):
		layer.disconnect("proportions_changed", self, "_on_layer_proportions_changed")
	if layer.is_connected("rotation_changed", self, "_on_layer_rotation_changed"):
		layer.disconnect("rotation_changed", self, "_on_layer_rotation_changed")
	
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
		active_button = null
		#active_button.snap(SNAP_SIZE) 
		#add_redo_action()


func left_click(event: InputEventMouseButton):
	if not layer is RegionLayer2D:
		l.g("Selected layer is not region layer on add region tool.")
		return
	
	var pos = event.position
	pos = canvas.convert_position(pos)
	var region = layer.create_region(pos)
	if region is RegionArea2D:
		region.bottom_right._on_button_down()
	
	return true


func left_click_drag(event: InputEventMouseMotion):
	if layer == null:
		return
	
	if active_button != null:
		active_button.move_by(
				canvas.convert_position_change(event.relative),
				snap,
				SNAP_SIZE)
