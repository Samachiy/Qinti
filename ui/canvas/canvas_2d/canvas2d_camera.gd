extends Camera2D

onready var grid = $Grid
onready var underlay = $Underlay

var underlay_scale = Vector2.ONE
var active_area_size = Vector2.ZERO
var current_zoom: float = 1.0

func _ready():
	current_zoom = zoom.x
	zoom.y = zoom.x
	grid.camera_ref = self
	grid.update()


func set_position_with_grid(pos: Vector2):
	position = pos
	var grid_offset_x = int(pos.x) % grid.primary_line_size
	var grid_offset_y = int(pos.y) % grid.primary_line_size
	grid.position = Vector2(-grid_offset_x, -grid_offset_y)


func set_zoom_with_grid(zoom_amount: float) -> bool:
	# returns true if changed and grid updated, false otherwise
	if zoom_amount == current_zoom:
		return false
	current_zoom = zoom_amount
	zoom = Vector2(zoom_amount, zoom_amount)
	underlay.scale = underlay_scale * zoom
	grid.update()
	return true


func set_underlay_size(new_size: Vector2):
	active_area_size = new_size
	update_underlayer_size()


func update_underlayer_size():
	if underlay.texture == null:
		underlay_scale = Vector2.ONE
		underlay.scale = underlay_scale
	else:
		underlay_scale = active_area_size / underlay.texture.get_size()
		underlay.scale = underlay_scale * zoom
	


func set_texture(image_texture: ImageTexture):
	if image_texture == null:
		underlay.texture = null
	else:
		underlay.texture = image_texture
		underlay_scale = active_area_size / underlay.texture.get_size()
		underlay.scale = underlay_scale * zoom


func _on_ActiveArea_active_area_resized(rect_size: Vector2):
	set_underlay_size(rect_size)


func _on_Underlay_texture_changed():
	update_underlayer_size()
