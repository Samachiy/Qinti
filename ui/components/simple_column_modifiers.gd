extends Container

export var image_spacing: int = 15
export var height_proportion: float = 0.55

var image_width: int = 0
var last_v_scroll_width: int = 0
var last_y_size: int = 1
var empty_space_index = -1 # -1 means none


# Called when the node enters the scene tree for the first time.
func _ready():
	_on_Container_resized()


func place_modifiers(y_pos_offset: int = 0):
	var y_pos = 0
	var image_height = image_width * height_proportion
	var i = 0
	for child in get_children():
		if not child.visible:
			continue
		
		if i == empty_space_index:
			y_pos += image_height + image_spacing
		
		if _is_modifier(child):
			child.rect_size = Vector2(image_width, image_height)
			child.rect_position.y = y_pos
			y_pos += image_height + image_spacing #+ child.get_editing_label_size()
		
		i += 1
	
	# in case the empty_space_index goes beyond child number (aka add empty space 
	# at the end)
	if i == empty_space_index:
		y_pos += image_height + image_spacing
	
# warning-ignore:narrowing_conversion
	last_y_size = max(y_pos + y_pos_offset - image_spacing, 0)
	rect_size.y = last_y_size
	rect_min_size.y = last_y_size


func _is_modifier(node: Node):
	return node is Modifier


func get_scroll_bar_width():
	var v_scroll = get_parent().get_v_scrollbar()
	if v_scroll.visible:
		return v_scroll.rect_size.x
	else:
		return 0


func calculate_empty_space_index(position: Vector2):
	var i = 0
	var mid_child_pos
	for child in get_children():
		if child is Control and child.visible:
			mid_child_pos = child.rect_position + child.rect_size / 2
		else:
			continue
		
		if mid_child_pos.y > position.y:
			break
		
		i += 1
	
	empty_space_index = i


func _on_Container_resized():
	yield(get_tree(), "idle_frame") # this prevents the placement func from freezing
	var v_scroll_width = get_scroll_bar_width()
	var new_width = rect_size.x
	var last_width = image_width
	if new_width != image_width:
		image_width = new_width
		if v_scroll_width != 0 and last_v_scroll_width == 0:
			#place_modifiers((v_scroll_width * height_proportion + 1) * get_child_count())
			place_modifiers(v_scroll_width / last_width * last_y_size + 1)
		else:
			place_modifiers(0)
		
		last_v_scroll_width = v_scroll_width


func refresh_order():
	pass
