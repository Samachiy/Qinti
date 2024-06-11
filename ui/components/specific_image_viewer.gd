extends MarginContainer

# The sender uses this object signals
# The receiver uses the special function connect_relay(), it does NOT connect
# to this object signals

onready var image_node = $MarginContainer/HBoxContainer/VBoxContainer/Image
onready var thumbnails = $MarginContainer/HBoxContainer/VBoxContainer/Thumbnails
onready var prev_button = $MarginContainer/HBoxContainer/Prev
onready var next_button = $MarginContainer/HBoxContainer/Next
onready var close_button = $MarginContainer/MarginContainer/ExtraButtons/Close
onready var menu = $"%Menu"

export(bool) var select_on_change = true

var thumbnail_packed_scene = preload("res://ui/components/specific_image_viewer_thumbnail.tscn")
var images: Array
var thumbnails_ref: Dictionary
var counter: int = -1
#var to_disconnect_on_close: Array
var image_viewer_relay: ImageViewerRelay = null
var thumbnail_x_padding = 10
var pressed_left = false
var pressed_right = false
var current_image_data: ImageData = null

# warning-ignore:unused_signal
signal image_selected(index, image)
# warning-ignore:unused_signal
signal image_changed(index, image)
# warning-ignore:unused_signal
signal viewer_closed(index, image)

func _ready():
	Roles.request_role(self, Consts.ROLE_SP_IMAGE_VIEWER)
	prev_button.modulate.a8 = Consts.LABEL_FONT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(prev_button, Consts.THEME_MODULATE_GROUP_TYPE)
	next_button.modulate.a8 = Consts.LABEL_FONT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(next_button, Consts.THEME_MODULATE_GROUP_TYPE)
	close_button.modulate.a8 = Consts.TERMINATE_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(close_button, Consts.THEME_MODULATE_GROUP_STYLE)
	_fill_menu()


func open_images(cue: Cue):
	# [image_data1, image_data2, ...]
	# { 'index' = int,
	# 	'relay': image_viewer_relay }
	var index = cue.int_option('index', 0)
	var relay = cue.object_option('relay')
	visible = true
	thumbnails.remove_children()
	
	counter = -1
	images = cue._arguments
	thumbnails_ref.clear()
	var is_multiple_images = images.size() > 1
	next_button.visible = is_multiple_images
	prev_button.visible = is_multiple_images
	thumbnails.visible = is_multiple_images
	
	var i = 0
	for image_data in images:
		add_thumnail(image_data, i)
		i += 1
	
	thumbnails.refresh()
	if images.size() > 0:
		load_image_at(index, '')
	
	image_viewer_relay = null
	if relay is ImageViewerRelay:
		image_viewer_relay = relay


func add_thumnail(image_data: ImageData, index: int):
	if image_data == null:
		return
	var thumbnail: Button = thumbnail_packed_scene.instance()
	thumbnail.icon = image_data.texture
	#thumbnail.rect_min_size.x = thumbnail.texture.get_size().x + thumbnail_x_padding
	thumbnail.index = index
	thumbnails.add_child_in_row(thumbnail)
	thumbnails_ref[index] = thumbnail
# warning-ignore:return_value_discarded
	thumbnail.connect("thumbnail_selected", self, "_on_thumbnail_selected")


func load_image_at(index: int, safe_signal: String):
	var thumbnail = thumbnails_ref.get(counter)
	if counter == index:
		return
	
	if thumbnail != null:
		thumbnail.remove_highlight()
	
	if images.empty():
		return
	
	if index < images.size():
		counter = index
	elif index < 0:
		counter = 0
	else:
		counter = images.size() - 1
	
	current_image_data = images[counter]
	image_node.texture = current_image_data.texture
	thumbnail = thumbnails_ref.get(counter)
	if thumbnail != null:
		thumbnail.highlight()
	
	if not safe_signal.empty():
		emit_safe_image_signal(safe_signal)


func select(index: int):
	# Select as in pressing an extra button to confirm selection
	load_image_at(index, "image_selected")


func next(_cue: Cue = null):
	if counter + 1 < images.size():
		load_image_at(counter + 1, "image_changed")
	else:
		load_image_at(0, "image_changed")


func prev(_cue: Cue = null):
	if counter - 1 >= 0:
		if counter - 1 < images.size():
			load_image_at(counter - 1, "image_changed")
		else:
			load_image_at(images.size() - 1, "image_changed")
	else:
		load_image_at(images.size() - 1, "image_changed")


func close(_cue: Cue = null):	
	emit_safe_image_signal("viewer_closed")
	thumbnails.remove_children()
	image_viewer_relay = null
	counter = -1
	visible = false


func emit_safe_image_signal(signal_name: String):
	if image_viewer_relay == null or not is_instance_valid(image_viewer_relay):
		l.g("Image viewer relay is " + str(image_viewer_relay))
	if counter in range(0, images.size()):
		image_viewer_relay.emit_signal(signal_name, counter, images[counter])


func _on_Prev_pressed():
	prev()


func _on_Next_pressed():
	next()


func _on_Close_pressed():
	close()


func _on_thumbnail_selected(index: int):
	load_image_at(index, "image_changed")


func _fill_menu():
	menu.add_tr_labeled_item(Consts.MENU_SAVE_IMAGE)
	menu.add_tr_labeled_item(Consts.MENU_SAVE_IMAGE_AS)


func _pop_up_menu():
	if not is_instance_valid(current_image_data):
		return
	
	menu.popup_at_cursor()


func _on_Image_gui_input(event):
	if not event is InputEventMouseButton:
		return
	
	# left click
	if event.get_button_index() == BUTTON_LEFT:
		if pressed_left and not event.pressed:
			pass # Nothing to do at the moment
		
		pressed_left = event.pressed
	# right click
	elif event.get_button_index() == BUTTON_RIGHT:
		if pressed_right and not event.pressed:
			_pop_up_menu()
		pressed_right = event.pressed


func _on_Menu_option_selected(label_id, _index_id):
	if not is_instance_valid(current_image_data):
		return
	
	match label_id:
		Consts.MENU_SAVE_IMAGE:
			var path = Cue.new(Consts.ROLE_FILE_PICKER, "get_default_save_path").execute()
			_on_save_path_selected(path, false)
		Consts.MENU_SAVE_IMAGE_AS:
			Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
					self,
					"_on_save_path_selected",
					FileDialog.MODE_SAVE_FILE
				]).opts({
					tr("SUPPORTED_SAVE_IMAGE_FORMAT"): "*.png" # donetr
				}).execute()


func _on_save_path_selected(path: String, overwrite: bool = true):
	ImageProcessor.save_image_data(current_image_data, path, "recent_image", true, overwrite)
