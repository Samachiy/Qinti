extends ReferenceRect

class_name RegionArea2D

const DESCRIPTION = "desc"

var limits: Rect2 = Rect2(rect_position, rect_size)
var data: Dictionary = {}

signal proportions_changed(limits)


func hide_interactables():
	for child in get_children():
		if child is Control:
			child.visible = false


func show_interactables():
	for child in get_children():
		if child is Control:
			child.visible = true


func refresh_region():
	rect_size = limits.size
	rect_position = limits.position


func _on_top_limit_changed_by(new_value: float):
	var diff = new_value
	limits = limits.grow_individual(0, diff, 0, 0)
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_region()


func _on_bottom_limit_changed_by(new_value: float):
	var diff = new_value 
	limits = limits.grow_individual(0, 0, 0, diff)
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_region()


func _on_right_limit_changed_by(new_value: float):
	var diff = new_value
	limits = limits.grow_individual(0, 0, diff, 0)
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_region()


func _on_left_limit_changed_by(new_value: float):
	var diff = new_value
	limits = limits.grow_individual(diff, 0, 0, 0)
	emit_signal("proportions_changed", limits)
	# This function will update the limits indicator according to limits
	refresh_region()

