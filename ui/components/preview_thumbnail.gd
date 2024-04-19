extends Thumbnail

class_name PreviewThumbnail

onready var frame = $Frame

var current_image: Image = null
var preview_size: int = 40
var margin_size: int = 15
var extra_margin: Vector2 = Vector2.ZERO

signal image_dropped(image_data)

func _ready():
	frame.modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
	UIOrganizer.add_to_theme_by_modulate_group(frame, Consts.THEME_MODULATE_GROUP_STYLE)


func _on_pressed():
	pass # Do nothing on press, this is so that the not-overriden error message doesn't pop


func _fill_menu():
	menu.add_tr_labeled_item(Consts.MENU_SAVE_PREVIEW)
	menu.add_tr_labeled_item(Consts.MENU_SAVE_PREVIEW_AS)


func _on_Menu_option_pressed(label_id, _index_id):
	match label_id:
		Consts.MENU_SAVE_PREVIEW:
			var path = Cue.new(Consts.ROLE_FILE_PICKER, "get_default_save_path").execute()
			_on_save_path_selected(path, false)
		Consts.MENU_SAVE_PREVIEW_AS:
			Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
					self,
					"_on_save_path_selected",
					FileDialog.MODE_SAVE_FILE
				]).opts({
					tr("SUPPORTED_SAVE_IMAGE_FORMAT"): "*.png" # donetr
				}).execute()


func _on_save_path_selected(path: String, overwrite: bool = true):
	if resolve_valid_image_data():
		ImageProcessor.save_image_data(current_image_data, path, "preview_image", true, overwrite)


func set_preview_dimensions(new_preview_size, new_margin_size):
	preview_size = new_preview_size
	margin_size = new_margin_size
	calculate_size()


func set_image(image: Image):
	current_image = image
	var image_texture: ImageTexture = ImageTexture.new()
	image_texture.create_from_image(image)
	current_image_data = null
	set_image_texture(image_texture)


func set_image_texture(image_texture: Texture):
	texture = image_texture
	var image_size: Vector2 = texture.get_size()
	vertical_proportion = image_size.y / float(image_size.x)
	current_image_data = null
	calculate_size()


func set_image_data(image_data_: ImageData):
	.set_image_data(image_data_)
	calculate_size()


func calculate_size():
	if texture == null:
		rect_min_size = Vector2.ZERO
		rect_size = Vector2.ZERO
		visible = false
		return
	
	visible = true
	var total_margin = extra_margin + Vector2(margin_size, margin_size)
	var width: float = texture.get_width()
	var height: float = texture.get_height()
	var proportion: float
	if width >= height:
		proportion = height / width
		width = preview_size
		height = preview_size * proportion
	else:
		proportion = width / height 
		height = preview_size
		width = preview_size * proportion
	
	rect_min_size = Vector2(width, height)
	rect_size = Vector2(width, height)
	
	if grow_horizontal == GROW_DIRECTION_BEGIN:
		margin_right = - total_margin.x
		margin_left = - width - total_margin.x
	else:
		margin_left = total_margin.x
		margin_right = width + total_margin.x
	
	if grow_vertical == GROW_DIRECTION_BEGIN:
		margin_bottom = - total_margin.y
		margin_top = - height - total_margin.y
	else:
		margin_top = total_margin.y
		margin_bottom = height + total_margin.y


func resolve_valid_image_data():
	var success = true
	if current_image_data is ImageData:
		pass # Success
	elif current_image is Image:
		current_image_data = ImageData.new("canvas_preview").load_image_object(current_image)
	elif texture is Texture:
		current_image_data = ImageData.new("canvas_preview").load_texture(texture)
	else:
		success = false
	
	return success


func set_preview_any_image_object(any_image_object):
	if any_image_object is ImageData:
		set_image_data(any_image_object)
	elif any_image_object is Image:
		set_image(any_image_object)
	elif any_image_object is Texture:
		set_image_texture(any_image_object)
	else:
		l.g("Can't set image in preview, not a valid type")


func create_img2img_modifier():
	# this thumbnail does not need to recreate itself
	create_empty_modifier()
	if modifier != null:
		modifier.set_as_image_type_alt(current_image_data)


func get_drag_data(_position: Vector2):
	if not resolve_valid_image_data():
		return
	
	create_img2img_modifier()
	
	var mydata = modifier
	var preview = TextureRect.new()
	preview.expand = true
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview.texture = current_image_data.texture
	preview.rect_size = rect_size
	set_drag_preview(preview)
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "set_on_top").args([preview]).execute()
	Cue.new(Consts.UI_DROP_GROUP, "enable_drop").execute()
	return mydata


func _on_DropArea_modifier_dropped(_position, modifier):
	if modifier is Modifier:
		set_image_data(modifier.image_data)
		var args = [current_image_data]
		Cue.new(Consts.ROLE_CANVAS, "set_images_in_generation_area").args(args).execute()
		emit_signal("image_dropped", current_image_data)
