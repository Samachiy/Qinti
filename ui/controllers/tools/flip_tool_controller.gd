extends ToolController

var flip_texture: Sprite = null
var flip_hidden_strokes: Dictionary = {}
var layer: Layer2D = null


func select_tool():
	layer = canvas.get_selected_layer()
	if layer == null:
		return
	
	visible = true


func deselect_tool():
	if layer == null:
		return
	
	visible = false
	if flip_texture == null:
		pass # nothignto do here
	elif flip_texture.flip_h or flip_texture.flip_v:
		var undoredo_act: Canvas2DUndoAction = canvas.add_texture_undoredo(flip_texture, layer)
		undoredo_act.add_undo_cue(Cue.new('', 'show_nodes').args(flip_hidden_strokes.values()))
		undoredo_act.add_undo_cue(Cue.new('', 'set_permanent_area_alpha').args([255]))
		undoredo_act.add_redo_cue(Cue.new('', 'hide_nodes').args(flip_hidden_strokes.values()))
		undoredo_act.add_redo_cue(Cue.new('', 'set_permanent_area_alpha').args([0]))
	else:
		flip_texture.queue_free()
	
	flip_hidden_strokes = {}
	layer = null


func _on_Reset_pressed():
	for node in flip_hidden_strokes.values():
		if not is_instance_valid(node):
			continue
		
		node.set("visible", true)
	
	flip_texture.queue_free()


func _on_FlipH_pressed():
	create_flip_screenshot()
	flip_texture.flip_h = not flip_texture.flip_h
	canvas.refresh_viewport()


func _on_FlipV_pressed():
	create_flip_screenshot()
	flip_texture.flip_v = not flip_texture.flip_v
	canvas.refresh_viewport()


func create_flip_screenshot():
	if flip_texture == null:
		var image = layer.get_image(Rect2(Vector2.ZERO, layer.limits.size))
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image)
		flip_texture = layer.draw_texture_at(image_texture, Vector2.ZERO, true)
		flip_hidden_strokes = layer.hide_strokes() # this needs to go after screenshot
		flip_texture.visible = true
# warning-ignore:return_value_discarded
		flip_hidden_strokes.erase(flip_texture)
