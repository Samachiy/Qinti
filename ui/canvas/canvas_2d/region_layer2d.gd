extends Control

class_name RegionLayer2D

const MIN_SIZE = 40

signal layer_edited()

var canvas = null


func create_region(pos: Vector2):
	# returns the newly created line 2d node if created, if not will return null
	var region = RegionArea2D.new()
	region.rect_position = pos
	region.rect_min_size = Vector2(MIN_SIZE, MIN_SIZE)
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
