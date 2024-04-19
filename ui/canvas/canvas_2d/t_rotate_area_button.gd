extends TextureButton

const PADDING = 25

signal angle_changed(angle)

var vertical: bool = false
var horizontal: bool = false
var parent = null
var layer = null
var valid_button = true
var canvas = null
var active = false
var movement_cache_x: float = 0
var movement_cache_y: float = 0
var type = ''

var scale_on_expand = true
var lock_proportions = false
var prev_global_pos: Vector2
var is_pressed: bool = false
var last_area_center: Vector2 = Vector2.ZERO

func _ready():
	if owner != null and owner is Layer2D:
		layer = owner
		canvas = owner.get("canvas")
	else:
		layer = null
		l.g('Invalid owner on transform area button at: ' + get_path())
		valid_button = false
	
	parent = get_parent()
	if parent != null and parent.get("ROTATE_NAME") != null:
		type = parent.get("ROTATE_NAME")
	else:
		parent = null
		l.g('Invalid parent on transform area button at: ' + get_path())
		valid_button = false
	
	if canvas == null:
		l.g('Invalid canvas on transform area button at: ' + get_path())
	
	margin_top = -texture_normal.get_size().y / 2
	margin_bottom = 0
	margin_left = PADDING
	margin_right = 0
	rect_pivot_offset.y = -margin_top
	connect_button()


func connect_button():
	var e = connect("gui_input", self, "_on_gui_input")
	l.error(e, l.CONNECTION_FAILED)
	e = connect("button_down", self, "_on_button_down")
	l.error(e, l.CONNECTION_FAILED)
	e = connect("button_up", self, "_on_button_up")
	l.error(e, l.CONNECTION_FAILED)
	if parent == null:
		return
	
	e = connect("angle_changed", layer, "rotate_to")
	l.error(e, l.CONNECTION_FAILED)


func rotate_by(relative_movement: Vector2):
	var angle = relative_movement.y + relative_movement.x
	rect_rotation += angle
	emit_signal("angle_changed", rect_rotation)


func snap(_snap_size: int):
	pass # Function here just for compatibility issues


func set_pivot(transform_area_center: Vector2):
	if is_pressed:
		last_area_center = transform_area_center
		return
	
	margin_left = transform_area_center.x + PADDING
	rect_pivot_offset.x = - transform_area_center.x


func _on_button_down():
	if layer == null:
		return
	
	is_pressed = true
	layer.activate_transfrom_button(self)


func _on_button_up():
	is_pressed = false
	if last_area_center == Vector2.ZERO:
		return
	
	set_pivot(last_area_center)
	rect_rotation = 0


func _on_gui_input(event):
	if canvas == null:
		return
	
	canvas._on_gui_input(event)


func activate():
	active = true


func deactivate():
	active = false
