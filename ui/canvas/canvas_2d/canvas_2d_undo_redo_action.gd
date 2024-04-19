extends Reference

class_name Canvas2DUndoAction

# undo/redo cues will be execute in owner_layer using Cue.execute_in_node(node)
var undo_cues = []
var redo_cues = []
var owner_layer: Control

# nodes that make possible the changes on the layers in the viewport
var change_nodes = [] 

func _init(owner_layer_: Control):
	owner_layer = owner_layer_
	if owner_layer == null:
		pass


func register_node(main_node: Node2D):
	change_nodes.append(main_node)


func add_undo_cue(cue: Cue):
	undo_cues.append(cue)


func add_redo_cue(cue: Cue):
	redo_cues.append(cue)


func undo():
	for node in change_nodes:
		if node is CanvasItem:
			node.visible = false
	
	for cue in undo_cues:
		if cue is Cue:
			cue.execute_in_node(owner_layer)
	
	owner_layer.emit_signal("layer_edited")


func redo():
	for node in change_nodes:
		if node is CanvasItem:
			node.visible = true
	
	for cue in redo_cues:
		if cue is Cue:
			cue.execute_in_node(owner_layer)
	
	owner_layer.emit_signal("layer_edited")


func destroy():
	for node in change_nodes:
		if node is CanvasItem:
			node.queue_free()


func merge():
	for node in change_nodes:
		if node is CanvasItem:
			owner_layer.move_to_permanent(node)
