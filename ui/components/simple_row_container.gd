extends Container

enum ALING{
	LEFT,
	CENTER,
	RIGHT,
}
var spacing: int = 10
var alignment: int = 0
var last_size
var last_h_scroll_height: int = 0
var last_x_size = 1

func place_children(x_pos_offset: int = 0):
	var x_pos = 0
	var x_proportion: float
	var child_size: Vector2
	for child in get_children():
		if child is TextureButton:
			child_size = child.texture_normal.get_size()
		elif child is TextureRect:
			child_size = child.texture.get_size()
		elif child is Button:
			child_size = child.icon.get_size()
		elif child is Control:
			child_size = child.rect_size
		else:
			continue
		
		x_proportion = child_size.x / child_size.y
		child.rect_min_size = Vector2.ZERO
		child.rect_size = Vector2(rect_size.y * x_proportion, rect_size.y)
		child.rect_position.x = x_pos
		x_pos += child.rect_size.x + spacing 
	
	
# warning-ignore:narrowing_conversion
	last_x_size = max(x_pos + x_pos_offset - spacing, 0)
	rect_min_size.x = last_x_size
	align()


func align():
	var leftover = get_parent().rect_size.x - last_x_size
	if leftover > 0:
		if alignment == ALING.CENTER:
			_offset_position_in_children(int(leftover / 2))
		elif alignment == ALING.RIGHT:
			_offset_position_in_children(int(leftover))


func _offset_position_in_children(offset_x: int):
	for child in get_children():
		if child is Control:
			child.rect_position.x += offset_x


func _on_Row_resized():
	yield(get_tree(), "idle_frame") # this prevents the placement func from freezing
	var h_scroll_height = get_scroll_bar_height()
	var new_size = rect_size
	if new_size != last_size:
		last_size = new_size
		if h_scroll_height != 0 and last_h_scroll_height == 0:
			place_children(h_scroll_height / new_size.y * last_x_size + 1)
		else:
			place_children()
		
		last_h_scroll_height = h_scroll_height



func get_scroll_bar_height():
	var h_scroll = get_parent().get_h_scrollbar()
	if h_scroll.visible:
		return h_scroll.rect_size.x
	else:
		return 0

