extends PopupMenu

const CURSOR_OFFSET = 8

var item_ids: Dictionary = {} # {index_number: string_id, ...}
var item_ids_by_label: Dictionary = {} # {string_id: index_number, ...}
var first_pop_up: bool = true

signal option_selected(label_id, index_id)


func _ready():
	var error = connect("id_pressed", self, "_on_Control_id_pressed")
	l.error(error, l.CONNECTION_FAILED)
	rect_size = Vector2.ZERO


func clear():
	.clear()
	first_pop_up = true
	item_ids.clear()
	item_ids_by_label.clear()


func add_tr_labeled_item(item_name: String, enabled: bool = true) -> int:
	# The translated item_name is the label and the untranslated is the id
	return add_labeled_item(item_name, item_name, enabled)


func set_tr_labeled_item(item_name: String, enabled: bool = true) -> int:
	# The translated item_name is the label and the untranslated is the id
	return set_labeled_item(item_name, item_name, enabled)


func add_labeled_item(item_name: String, item_label_id, enabled: bool = true) -> int:
	# The translated of the item_name is the text and the item_label_id is the id
	var index_num = get_item_count()
	add_item(item_name, index_num)
	item_ids[index_num] = item_label_id
	item_ids_by_label[item_label_id] = index_num
	set_item_disabled(index_num, not enabled)
	return index_num


func set_labeled_item(item_name: String, item_label_id, enabled: bool = true) -> int:
	# The translated of the item_name is the text and the item_label_id is the id
	var index_num = item_ids_by_label.get(item_label_id, null)
	if index_num == null:
		index_num = add_labeled_item(item_name, item_label_id, enabled)
	else:
		set_item_text(index_num, item_name)
		set_item_disabled(index_num, not enabled)
	
	return index_num


func popup_at_cursor():
	var viewport = get_tree().get_root()
	var cursor_pos: Vector2 = viewport.get_mouse_position() + Vector2(CURSOR_OFFSET, CURSOR_OFFSET)
	var screen_size: Vector2 = viewport.size
	
	# Because the size won't be updated until one frame after it is visible for the first time
	# we need to wait for the size the update if it's the first popup
	if first_pop_up:
		modulate.a = 0
		visible = true
		yield(get_tree(), "idle_frame")
		modulate.a = 1
		first_pop_up = false
	
	var size_x = rect_size.x  
	var size_y = rect_size.y 
	if cursor_pos.x + size_x > screen_size.x:
		cursor_pos.x -= size_x + CURSOR_OFFSET * 2
	if cursor_pos.y + size_y > screen_size.y:
		cursor_pos.y -= size_y + CURSOR_OFFSET * 2
	
	if cursor_pos.x < 0:
		cursor_pos.x = 0
	if cursor_pos.y < 0:
		cursor_pos.y = 0
	
	popup(Rect2(cursor_pos, rect_size))


func _on_Control_id_pressed(num_id):
	emit_signal("option_selected", item_ids.get(num_id), num_id)
