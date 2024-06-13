extends Thumbnail

class_name RecentThumbnail

onready var count_label = $Label
onready var highlight = $Highlight

var images_data: Array = []
var image_viewer_relay: ImageViewerRelay
var current_image_index: int = 0


func _ready():
	highlight.visible = false
	count_label.visible = false


func set_batch_image_data(images_data_: Array):
	if images_data_.empty():
		return false
	
	images_data = images_data_
	update_count_label()
	
	current_image_index = 0
	set_image_data(images_data[current_image_index])
	
	return true


func load_image_data_by_index(index: int):
	if index < images_data.size():
		update_count_label()
		current_image_index = index
		set_image_data(images_data[current_image_index])


func get_current_image_data() -> ImageData:
	if current_image_index < images_data.size():
		return images_data[current_image_index]
	else:
		return null


func update_count_label():
	if images_data.size() == 1:
		count_label.visible = false
	else:
		count_label.visible = true
		count_label.text = str(images_data.size())


func get_base64_images():
	var result = []
	for image in images_data:
		if image is ImageData:
			result.append([image.image_name, image.base64])
	
	return result


func set_up_relay():
	image_viewer_relay = ImageViewerRelay.new()
	image_viewer_relay.connect_relay(self, "_on_image_change_requested")


func is_match(text: String):
	if current_image_data == null:
		return text.empty() # If there's nothing to match, will return true
		
	if text.empty():
		return true
	
	return current_image_data.match_string(text)


func _on_pressed():
	_open_in_image_viewer()


func _fill_menu():
	menu.add_tr_labeled_item(Consts.MENU_SAVE_IMAGE)
	menu.add_tr_labeled_item(Consts.MENU_SAVE_IMAGE_AS)
	menu.add_separator()
	menu.add_tr_labeled_item(Consts.MENU_DELETE)


func _on_Menu_option_pressed(label_id, _index_id):
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
		Consts.MENU_DELETE:
			delete()


func delete():
	var error = connect("tree_exited", self, "_on_deleted")
	l.error(error, l.CONNECTION_FAILED)
	queue_free()


func _on_save_path_selected(path: String, overwrite: bool = true):
	ImageProcessor.save_image_data(current_image_data, path, "recent_image", true, overwrite)


func _open_in_image_viewer():
	var cue = Cue.new(Consts.ROLE_SP_IMAGE_VIEWER, 'open_images')
	cue._arguments = images_data
	cue._options = { 'index': current_image_index, 'relay': image_viewer_relay }
	cue.execute()


func _on_image_change_requested(index, image: ImageData):
	if image != null:
		current_image_index = index
		set_image_data(image)
		create_info_modifier()


func _on_deleted():
	Cue.new(Consts.ROLE_TOOLBOX, "refresh_recent_images_order").execute()
	


func _on_RecentThumbnail_mouse_entered():
	highlight.modulate = ThemeChanger.get_accent_color()
	highlight.visible = true


func _on_RecentThumbnail_mouse_exited():
	highlight.visible = false


func get_drag_data(position: Vector2):
	create_info_modifier()
	return .get_drag_data(position)
