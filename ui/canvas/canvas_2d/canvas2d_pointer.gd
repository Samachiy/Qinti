extends Node2D


var draw_cues: Array = []
var screen_invert_colors_material
var size = 0
var mode
var should_draw = true

func _ready():
	screen_invert_colors_material = material


func draw_circle_pointer(center_pos: Vector2, brush_size: float):
	position = center_pos
	size = brush_size
	should_draw = true
	update()


func _circle_pointer_cue(cue: Cue = null):
	# [ size ]
	size = cue.float_at(2, 0.0)
	draw_arc(Vector2(0, 0), size, 0, TAU, size + 3, Color.black, 1.0, false)


func _circle_pointer():
	draw_arc(Vector2(0, 0), size, 0, TAU, size + 3, Color.black, 1.0, false)
	


func _draw():
	if not should_draw:
		return
	
	_circle_pointer()


func clear():
	draw_cues = []
	should_draw = false
	update()
