extends Control

class_name RegionLayer2D

const MIN_SIZE = 40
const REGION_AREA_SCENE = "res://ui/canvas/canvas_2d/region_layer2d_area.tscn"

signal layer_edited()

var canvas = null
var region_area_scene = preload(REGION_AREA_SCENE)


func create_region(pos: Vector2):
	# returns the newly created line 2d node if created, if not will return null
	var region = region_area_scene.instance()
	region.rect_position = pos
	region.rect_min_size = Vector2(MIN_SIZE, MIN_SIZE)
	region.canvas = canvas
	region.layer = self
	add_child(region)
	emit_signal("layer_edited")
	return region



func activate_transfrom_button(button: Control):
	if canvas == null:
		return
	
	canvas.emit_signal("layer_region_resize_button_pressed", button)


func get_regions_data() -> Dictionary:
	var data = {} # { child1: [rect2_1, data_dict1], child2: [rect2_2, data_dict2], ... ]
	for child in get_children():
		if child is RegionArea2D:
			data[child] = [child.limits, child.data]
	
	return data


func hide_regions():
	for child in get_children():
		if child is Control:
			child.visible = false


func show_regions():
	for child in get_children():
		if child is Control:
			child.visible = true
