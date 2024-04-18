extends Node2D

const GRID_TRANSPARENCY = 100

enum{
	GRID,
	SOLID_BACKGROUND,
}

var snap: int = 8
var close_zoom_grid_size: int = 8
var close_zoom_threeshold: float = 0.5
var grid_size: int = 128
var primary_line_steps: int = 4
var camera_ref = null
var primary_line_size = primary_line_steps * grid_size

var type: int = GRID
var color: Color = Color.white


func _draw():
	match type:
		GRID:
			_draw_grid()
		SOLID_BACKGROUND:
			_draw_solid_background()


func set_as_grid(grid_color: Color = color):
	type = GRID
	color = grid_color
	update()


func set_as_solid_background(grid_color: Color = color):
	type = SOLID_BACKGROUND
	color = grid_color
	update()


func _draw_solid_background():
	if camera_ref == null:
		return
	
	var size = get_viewport().size * 20
	var end_x = size.x / 2
	var start_x = -end_x
	var end_y = size.y / 2
	var start_y = -end_y
	var rect = Rect2(Vector2(start_x, start_y), size)
	draw_rect(rect, color, true)
	modulate.a8 = 255


func _draw_grid():
	if camera_ref == null:
		return
	
	var size = get_viewport().size * 20
	var end_x = size.x / 2
	var start_x = -end_x
	var end_y = size.y / 2
	var start_y = -end_y
	var dot_size
	if camera_ref.zoom.x < 1:
		dot_size = 1 * camera_ref.zoom.x
	else:
		dot_size = camera_ref.zoom.x
	
	var color_thin_line = color
	color_thin_line.a8 = 255
	var color_primary_line = color
	color_primary_line.a8 = 255
	
	# thin lines x axis
	for x in range(0, start_x, -grid_size):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color_thin_line, dot_size)
	for x in range(0, end_x, grid_size):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color_thin_line, dot_size)
		
	# thin lines y axis
	for y in range(0, start_y, -grid_size):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color_thin_line, dot_size)
	for y in range(0, end_y, grid_size):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color_thin_line, dot_size)
		
	# thick lines x axis
	for x in range(0, start_x, -primary_line_size):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color_primary_line, dot_size * 2)
	for x in range(primary_line_size, end_x, primary_line_size):
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color_primary_line, dot_size * 2)
		
	# thick lines y axis
	for y in range(0, start_y, -primary_line_size):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color_primary_line, dot_size * 2)
	for y in range(primary_line_size, end_y, primary_line_size):
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color_primary_line, dot_size * 2)
	
	modulate.a8 = GRID_TRANSPARENCY
	
	if camera_ref.zoom.x < close_zoom_threeshold:
		var color_extra_thin_line = color
		color_extra_thin_line.a8 = 200
		# extra thin lines x axis
		for x in range(0, start_x, -close_zoom_grid_size):
			draw_line(Vector2(x, start_y), Vector2(x, end_y), color_extra_thin_line, dot_size)
		for x in range(0, end_x, close_zoom_grid_size):
			draw_line(Vector2(x, start_y), Vector2(x, end_y), color_extra_thin_line, dot_size)
			
		# extra thin lines y axis
		for y in range(0, start_y, -close_zoom_grid_size):
			draw_line(Vector2(start_x, y), Vector2(end_x, y), color_extra_thin_line, dot_size)
		for y in range(0, end_y, close_zoom_grid_size):
			draw_line(Vector2(start_x, y), Vector2(end_x, y), color_extra_thin_line, dot_size)
		
