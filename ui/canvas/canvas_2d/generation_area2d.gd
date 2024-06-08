extends Layer2D

class_name GenerationArea2D

const SIGNAL_VIEW_CHANGED_DELAY = 0.2
const IDLE_VIEW_CHANGED_DELAY = 1.2
const EDIT_VIEW_CHANGED_DELAY = 0.8

onready var view_changed_timer = $ViewChangedTimer

var images_data: Array = []
var result_sublayer = null
var current_image_data: ImageData = null
var send_bg_if_empty: bool = false
var counter: int = 0
var is_image_edited: bool = false
var pending_view_update: bool = false

signal view_changed(image)

func _ready():
	transform_frame.visible = true
	has_max_size = true
	var error = connect("layer_moved", self, "_on_layer_moved")
	l.error(error, l.CONNECTION_FAILED)
	error = connect("layer_edited", self, "_on_layer_edited")
	l.error(error, l.CONNECTION_FAILED)
	error = connect("proportions_changed", self, "_on_proportions_changed")
	l.error(error, l.CONNECTION_FAILED)
	error = connect("rotation_changed", self, "_on_rotation_changed")
	l.error(error, l.CONNECTION_FAILED)
	view_changed_timer.wait_time = IDLE_VIEW_CHANGED_DELAY
	error = pivot_area.connect("child_entered_tree", self, "_on_Pivot_child_entered_tree")
	l.error(error, l.CONNECTION_FAILED)


# This block is just here for testing purposes
#func _process(delta):
#	if is_visible_in_tree():
#		if Input.is_action_just_pressed("ui_up"):
#			get_contained_image()


func get_limits_with_margin():
	var margin = Vector2(12, 12)
	var area = limits
	area.size += margin
	area.position -= margin / 2
	return area
	


func set_area_size(new_size: Vector2):
	var prev_pos = rect_position
	.set_max_size(Rect2(prev_pos, new_size))
	transform_frame.rect_size = new_size


func get_rect2():
	return Rect2(display.rect_position, limits.size)


func set_images_data(images_data_array: Array):
	if images_data_array.empty():
		return
	
	clear_images()
	images_data = images_data_array
	set_image(images_data[0])
	is_image_edited = false


func set_image(image_data: ImageData):
	if not is_instance_valid(result_sublayer):
		result_sublayer = null
	
	current_image_data = image_data
	result_sublayer = draw_texture_at(image_data.texture, limits.position, false, result_sublayer)
	refresh_size_with(Rect2(limits.position, image_data.get_size()))
	#canvas.add_texture_undoredo(result_sublayer, self)
	yield(get_tree(), "idle_frame")
	_on_ViewChangedTimer_timeout()
	refresh_viewport()


func set_image_num(index: int):
	if index in range(0, images_data.size()):
		set_image(images_data[index])
		counter = index


func next(image_viewer_relay: ImageViewerRelay):
	var new_pos = counter
	if counter + 1 < images_data.size():
		new_pos += 1
	else:
		new_pos = 0 
	
	if new_pos == counter:
		return
	
	counter = new_pos
	#set_image(images_data[counter]) # the signal below will take charge of loading the image
	if image_viewer_relay != null:
		image_viewer_relay.emit_signal("image_changed", counter, images_data[counter])


func prev(image_viewer_relay: ImageViewerRelay):
	var new_pos = counter
	if counter - 1 >= 0:
		if counter - 1 < images_data.size():
			new_pos -= 1
		else:
			new_pos = images_data.size() - 1
	else:
		new_pos = images_data.size() - 1
	
	if new_pos == counter:
		return
	
	counter = new_pos
	#set_image(images_data[counter]) # the signal below will take charge of loading the image
	if image_viewer_relay != null:
		image_viewer_relay.emit_signal("image_changed", counter, images_data[counter])


func clear_images():
	current_image_data = null
	images_data = []
	result_sublayer = null
	counter = 0 
	clear_image()
	is_image_edited = false
	_on_ViewChangedTimer_timeout()


func _on_layer_moved(_limits):
	view_changed_timer.stop()
	view_changed_timer.start(SIGNAL_VIEW_CHANGED_DELAY)


func _on_layer_edited():
	view_changed_timer.stop()
	view_changed_timer.start(EDIT_VIEW_CHANGED_DELAY)


func _on_layer_created(layer):
	if layer is Layer2D:
		layer.connect("layer_edited", self, "_on_layer_edited")


func _on_rotation_changed(_angle):
	view_changed_timer.stop()
	view_changed_timer.start(SIGNAL_VIEW_CHANGED_DELAY)


func _on_proportions_changed(_limits):
	view_changed_timer.stop()
	view_changed_timer.start(SIGNAL_VIEW_CHANGED_DELAY)


func get_contained_image(get_bg_image_if_empty: bool = true) -> Image:
	if current_image_data != null:
		if current_image_data.get_size() == limits.size and not is_image_edited:
			return current_image_data.image
		else:
			return get_visible_image()
	
	# If we reach here, that means the image is empty, so we need to check if
	# we have to retrieve what is in the background instead or just return null
	if get_bg_image_if_empty:
		return canvas.get_canvas_image(limits, false)
	else:
		return null


func get_contained_mask():
	var mask_image_data
	if current_image_data != null:
		mask_image_data = get_visible_mask()
		if mask_image_data.is_invisible():
			mask_image_data = canvas.get_canvas_mask(limits)
	else:
		mask_image_data = canvas.get_canvas_mask(limits)
	
	return mask_image_data


func connect_view_changed(object: Object, method: String):
	var error = connect("view_changed", object, method)
	l.error(error, l.CONNECTION_FAILED)
	_on_ViewChangedTimer_timeout()


func _on_ViewChangedTimer_timeout():
	if not canvas.is_visible_in_tree():
		pending_view_update = true
		view_changed_timer.stop()
		view_changed_timer.start(IDLE_VIEW_CHANGED_DELAY)
		return
	
	pending_view_update = false
	view_changed_timer.stop()
	if canvas.is_visible_in_tree():
		emit_signal("view_changed", get_contained_image(send_bg_if_empty))


func _on_Pivot_child_entered_tree(_node):
	is_image_edited = true
