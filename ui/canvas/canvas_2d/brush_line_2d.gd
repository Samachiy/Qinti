extends Node2D

class_name BrushLine2D

const POINT_SEPARATION = 1

const POSITION = 0
const SIZE = 1
const COLOR = 2
const TYPE = 3

enum {
	CIRCLE
}

var default_type: int = CIRCLE
var default_color: Color = Color.pink
var width: float = 20.0
var points: Array
var last_point = null
#var group_opacity_shader = preload("res://ui/shaders/group_opacity_shader.tres")
#var group_opacity_eraser_shader = preload("res://ui/shaders/group_opacity_eraser_shader.tres")


#func _ready():
#	if modulate.a8 != 255:
#		l.p("adding opacity shader to brush line 2d")
#		var new_material = ShaderMaterial.new()
#		if material is CanvasItemMaterial:
#			if material.blend_mode == CanvasItemMaterial.BLEND_MODE_MIX:
#				new_material.shader = group_opacity_shader
#			elif material.blend_mode == CanvasItemMaterial.BLEND_MODE_SUB:
#				new_material.shader = group_opacity_eraser_shader
#
#		new_material.set_shader_param("opacity", modulate.a)
#		material = new_material
#		modulate.a8 = 255


func add_point(pos: Vector2, interpolate = true, update = true):
	if not is_distinctive_point(pos):
		return
	
	var point = {}
	point[POSITION] = pos
	if interpolate:
		add_interpolated_points(point)
	points.append(point)
	last_point = point
	if update:
		update()


func _draw():
	for point in points:
		match point.get(TYPE, CIRCLE):
			CIRCLE: 
				draw_circle(
						point.get(POSITION), 
						point.get(SIZE, width), 
						point.get(COLOR, default_color)
					)


func add_interpolated_points(point: Dictionary):
	# This point interpolation works good enough, so I will leave it at that
	# It will be improved on demand
	if not last_point is Dictionary:
		return
	
	var distance = point.get(POSITION).distance_to(last_point.get(POSITION))
	if distance <= POINT_SEPARATION:
		return
	
	var steps = int(distance * 2.5 / width)
	if steps == 0: 
		return
	
	var interpolation_rate = 1 / float(steps)
	#l.p("interpolation at: " + str(interpolation_rate))
	var pos
	for i in range(0, steps):
		pos = last_point.get(POSITION).linear_interpolate(point.get(POSITION), interpolation_rate * i)
		add_point(pos, false, false)


func is_distinctive_point(point_pos: Vector2) -> bool:
	if not last_point is Dictionary:
		return true # first point, so no conflict
	
	var sqr_distance = point_pos.distance_squared_to(last_point.get(POSITION))
	if sqr_distance >= POINT_SEPARATION:
		return true
	else:
		#l.p('no distinct')
		return false



