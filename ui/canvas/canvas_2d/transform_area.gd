extends ReferenceRect

# These two consts need to be in sync withe consts in transfrom_selection_tool_controller.gd
# These are not applied to global consts due to being extramelly local to this case
const ROTATE_NAME = 'rotate'
const SCALE_NAME = 'scale'

var scale_on_expand = false setget set_scale_on_expand
var lock_proportions = false setget set_lock_proportions

# We set this variable to null because some nodes that have the transform_area.dg
# do not have the rotate button
var rotate_button = null


func _ready():
	rotate_button = get_node_or_null("Rotate")
	_on_resized()
	var error = connect("resized", self, "_on_resized")
	l.error(error, l.CONNECTION_FAILED)


func set_scale_on_expand(value: bool):
	scale_on_expand = value
	for child in get_children():
		if child is TextureButton:
			child.scale_on_expand = value


func set_lock_proportions(value: bool):
	scale_on_expand = value
	for child in get_children():
		if child is TextureButton:
			child.lock_proportions = value


func _on_resized():
	if rotate_button == null:
		return
	
	rotate_button.set_pivot(get_rect().size/2)


func move_rotation_indicator(angle: float):
	if rotate_button == null:
		return
	
	rotate_button.rect_rotation = angle


func hide_interactables():
	for child in get_children():
		if child is Control:
			child.visible = false


func show_interactables():
	for child in get_children():
		if child is Control:
			child.visible = true
