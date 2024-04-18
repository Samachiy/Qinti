extends TextureButton



signal top_moved(by_y_pos, scale)
signal bottom_moved(by_y_pos, scale)
signal right_moved(by_x_pos, scale)
signal left_moved(by_x_pos, scale)

export var top: bool = false
export var bottom: bool = false
export var right: bool = false
export var left: bool = false

var vertical: bool = false
var horizontal: bool = false
var parent = null
var layer = null
var valid_button = true
var canvas = null
var active = false
var movement_cache_x: float = 0
var movement_cache_y: float = 0

var scale_on_expand = false
var lock_proportions = false
var type = ''
var viewport_container: ViewportContainer = null

func _ready():
	if owner != null and owner is Layer2D:
		layer = owner
		canvas = owner.get("canvas")
	else:
		layer = null
		l.g('Invalid owner on transform area button at: ' + get_path())
		valid_button = false
	
	parent = get_parent()
	if parent != null and parent.get("SCALE_NAME") != null:
		type = parent.get("SCALE_NAME")
	else:
		parent = null
		l.g('Invalid parent on transform area button at: ' + get_path())
		valid_button = false
	
	if canvas == null:
		l.g('Invalid canvas on transform area button at: ' + get_path())
	
	# validating proper button configuration
	if top and bottom:
		l.g('Invalid vertical direction on transform area button at: ' + get_path())
		valid_button = false
	elif top or bottom:
		vertical = true
	
	if right and left:
		l.g('Invalid horizontal direction on transform area button at: ' + get_path())
		valid_button = false
	elif right or left:
		horizontal = true
	
	if not horizontal and not vertical:
		l.g('Nonexisting direction on transform area button at: ' + get_path())
		valid_button = false
	
	if valid_button:
		connect_button()
		offset_texture()


func connect_button():
	var e = connect("gui_input", self, "_on_gui_input")
	l.error(e, l.CONNECTION_FAILED)
	e = connect("button_down", self, "_on_button_down")
	l.error(e, l.CONNECTION_FAILED)
	if parent == null:
		return
	
# warning-ignore:return_value_discarded
	connect("top_moved", layer, "_on_top_limit_changed_by")
# warning-ignore:return_value_discarded
	connect("bottom_moved", layer, "_on_bottom_limit_changed_by")
# warning-ignore:return_value_discarded
	connect("right_moved", layer, "_on_right_limit_changed_by")
# warning-ignore:return_value_discarded
	connect("left_moved", layer, "_on_left_limit_changed_by")


func _on_button_down():
	if layer == null:
		return
	
	if viewport_container == null:
		viewport_container = get_viewport().get_parent()
	
	if viewport_container.get_global_rect().has_point(viewport_container.get_global_mouse_position()):
		layer.activate_transfrom_button(self)


func _on_gui_input(event):
	if canvas == null:
		return
	
	canvas._on_gui_input(event)


func get_fix_sign() -> int:
	# hard coded sign fix for the absolute shit show that is resizing using rect2.grow_rect()
	# when working with with buttons whose resulting value changes depending on their position
	# on the image frame
	# There are better ways, but this one doesn't involve major code changes, doesn't add more 
	# convoluted code and performance hit is minimal. Elegance be dammed lol
	if top and right:
		return -1
	elif bottom and left:
		return -1
	elif top and left:
		return 1
	elif left or top:
		return -1
	else:
		return 1


func move_by(relative_movement: Vector2, cache_movement: bool = false, cache_limit: int = 8):
	# The cache is meant to store the movement until we get enough to change the size
	# up to snap distance (aka cache limit)
	var amount: float
	if lock_proportions:
		var abs_rel_movement = relative_movement.abs()
		if abs_rel_movement.y >= abs_rel_movement.x:
			relative_movement.x = layer.limits.size.x / layer.limits.size.y * relative_movement.y
			relative_movement.x *= get_fix_sign()
		else:
			relative_movement.y = layer.limits.size.y / layer.limits.size.x * relative_movement.x
			relative_movement.y *= get_fix_sign()
	
	if top:
		movement_cache_y += relative_movement.y
		if not cache_movement:
			emit_signal("top_moved", -movement_cache_y, scale_on_expand)
			movement_cache_y = 0
		elif abs(movement_cache_y) >= cache_limit:
			amount = int(movement_cache_y / cache_limit) * cache_limit # we round it
			emit_signal("top_moved", -amount, scale_on_expand)
			movement_cache_y = movement_cache_y - amount
	elif bottom:
		movement_cache_y += relative_movement.y
		if not cache_movement:
			emit_signal("bottom_moved", movement_cache_y, scale_on_expand)
			movement_cache_y = 0 
		elif abs(movement_cache_y) >= cache_limit:
			amount = int(movement_cache_y / cache_limit) * cache_limit # we round it
			emit_signal("bottom_moved", amount, scale_on_expand)
			movement_cache_y = movement_cache_y - amount
	elif lock_proportions:
		# Copy of bottom
		movement_cache_y += relative_movement.y
		if not cache_movement:
			emit_signal("bottom_moved", movement_cache_y, scale_on_expand)
			movement_cache_y = 0 
		elif abs(movement_cache_y) >= cache_limit:
			amount = int(movement_cache_y / cache_limit) * cache_limit # we round it
			emit_signal("bottom_moved", amount, scale_on_expand)
			movement_cache_y = movement_cache_y - amount
	
	if right:
		movement_cache_x += relative_movement.x
		if not cache_movement:
			emit_signal("right_moved", movement_cache_x, scale_on_expand)
			movement_cache_x = 0 
		elif abs(movement_cache_x) >= cache_limit:
			amount = int(movement_cache_x / cache_limit) * cache_limit # we round it
			emit_signal("right_moved", amount, scale_on_expand)
			movement_cache_x = movement_cache_x - amount
	elif left:
		movement_cache_x += relative_movement.x
		if not cache_movement:
			emit_signal("left_moved", -movement_cache_x, scale_on_expand)
			movement_cache_x = 0
		elif abs(movement_cache_x) >= cache_limit:
			amount = int(movement_cache_x / cache_limit) * cache_limit # we round it
			emit_signal("left_moved", -amount, scale_on_expand)
			movement_cache_x = movement_cache_x - amount
	elif lock_proportions:
		# Copy of right
		movement_cache_x += relative_movement.x
		if not cache_movement:
			emit_signal("right_moved", movement_cache_x, scale_on_expand)
			movement_cache_x = 0 
		elif abs(movement_cache_x) >= cache_limit:
			amount = int(movement_cache_x / cache_limit) * cache_limit # we round it
			emit_signal("right_moved", amount, scale_on_expand)
			movement_cache_x = movement_cache_x - amount


func snap(grid_size: int):
	if parent == null:
		return

	movement_cache_x = 0
	movement_cache_y = 0
	var snap_amount_x = int(parent.rect_size.x)
	snap_amount_x = (snap_amount_x % grid_size) + parent.rect_size.x - snap_amount_x
	var snap_amount_y = int(parent.rect_size.y)
	snap_amount_y = (snap_amount_y % grid_size) + parent.rect_size.y - snap_amount_y
	if top:
		emit_signal("top_moved", -snap_amount_y, scale_on_expand)
	elif bottom:
		emit_signal("bottom_moved", -snap_amount_y, scale_on_expand)

	if right:
		emit_signal("right_moved", -snap_amount_x, scale_on_expand)
	elif left:
		emit_signal("left_moved", -snap_amount_x, scale_on_expand)


func offset_texture():
	var offset = texture_normal.get_size() / 2
	var in_box_amount = offset #Vector2.ZERO
	if top:
		margin_top = - offset.y
		margin_bottom = in_box_amount.y
	elif bottom:
		margin_bottom = - offset.y
		margin_top = - in_box_amount.y

	if right:
		margin_right = - offset.x
		margin_left = - in_box_amount.x
	elif left:
		margin_left = - offset.x
		margin_right = in_box_amount.x


func activate():
	active = true


func deactivate():
	active = false
