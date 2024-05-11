extends Node

onready var viewport_container = $ViewportContainer
onready var viewport = $ViewportContainer/Viewport
onready var sprite = $ViewportContainer/Viewport/Sprite

var outpaint_material = preload("res://ui/shaders/empty_area_mask_material.tres")

var available: bool = true

enum{
	DEFAULT,
	EXPAND,
	FIT_INSIDE,
	FIT_OUTSIDE,
	CROP_CENTER,
}
var default_fit = CROP_CENTER

signal image_processed(image)


func _ready():
	if name == "ImageProcessor":
		viewport_container.visible = false
		return
	
	yield(get_tree().current_scene, "ready")
	yield(VisualServer, "frame_post_draw")


func process_image(image: Image, material: Material, target: Object, method: String, binds: Array = []):
	if not available:
		l.g("Can't process image, image processing node is busy")
	
	var processed_image
	var image_texture = ImageTexture.new()
	available = false
	viewport_container.visible = true
	image_texture.create_from_image(image)
	image_texture.flags = 5
	viewport.size = image.get_size()
	viewport_container.rect_size = image.get_size()
	sprite.texture = image_texture
	sprite.material = material
	processed_image = viewport.get_texture().get_data()
	var error = connect("image_processed", target, method, binds)
	
	yield(VisualServer, "frame_post_draw")
	processed_image = viewport.get_texture().get_data()
	l.error(error, l.CONNECTION_FAILED + "on process_image")
	
	sprite.texture = null
	sprite.material = null
	viewport_container.visible = false
	emit_signal("image_processed", processed_image)
	if is_connected("image_processed", target, method):
		disconnect("image_processed", target, method)
	available = true
	# if the same target and method is being used in the function that recives
	# the signal, then a new connect("image_processed", target, method, binds)
	# will be made before the CONNECT_ONESHOT deletes the connection, causing bugs
	


func image_to_base64(image: Image):
	if image == null:
		return ''
	
	return Marshalls.raw_to_base64(image.save_png_to_buffer())



func blend_images(base_image: Image, blend_image: Image, fit_mode: int = DEFAULT):
	var fitted_blend_image = blend_image
	var base_size = base_image.get_size()
	var blend_image_area = Rect2(Vector2.ZERO, base_size)
	var paste_image_at = Vector2.ZERO
	if blend_image.get_size() != base_size:
		if fit_mode == DEFAULT:
			fit_mode = default_fit
		
		fitted_blend_image = fit_image_in_rect2(blend_image, base_size, fit_mode)
	
	fitted_blend_image.convert(Image.FORMAT_RGBA8)
	base_image.blend_rect(
			fitted_blend_image, 
			blend_image_area, 
			paste_image_at)


func fit_image_in_rect2(image: Image, fit_size: Vector2, fit_mode: int):
	var image_size = image.get_size()
	if image_size.x < 1 or image_size.y < 1:
		l.g("Can't fit images without size, procedding to just center image")
		fit_mode = CROP_CENTER
	
	var fitted_image = image
	var resize_as = Vector2.ZERO
	var center = false
	# Expand requieres just to resize, crop center requieres just 
	# to center (and Image.get_rect), fit inside and outside requieres 
	# to both resize and center
	# We used that fact to summarize those four fit modes into this  
	# unnecesarily succinct code block
	# Dumb code is always more mantainable that clever code, but this
	# comment should bridge that gap. Please fix it if it doesn't, future me
	match fit_mode:
		EXPAND:
			resize_as = fit_size
		CROP_CENTER:
			center = true
		FIT_OUTSIDE:
			var ratio = fit_size / image_size
			center = true
			if ratio.x >= ratio.y:
				resize_as = image_size * ratio.x
			else:
				resize_as = image_size * ratio.y
		FIT_INSIDE:
			var ratio = fit_size / image_size
			center = true
			if ratio.x <= ratio.y:
				resize_as = image_size * ratio.x
			else:
				resize_as = image_size * ratio.y
	
	if resize_as != Vector2.ZERO:
		fitted_image = Image.new()
		fitted_image.copy_from(image)
		fitted_image.resize(resize_as.x, resize_as.y)
	
	fitted_image.convert(Image.FORMAT_RGBA8)
	if center:
		var pos = fitted_image.get_size() * 0.5
		pos -= (fit_size * 0.5)
		# get_rect also add empty space when needed, so this works
		fitted_image = fitted_image.get_rect(Rect2(pos, fit_size))
	
	return fitted_image


func add_background_to_image(image: Image, color: Color) -> Image:
	var new_image : Image = Image.new()
	var size = image.get_size()
	new_image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	new_image.fill(color)
	new_image.blend_rect(image, Rect2(Vector2.ZERO, size), Vector2.ZERO)
	return new_image


func save_image(image: Image, path: String, default_name: String = "", 
datetime_on_default: bool = true, overwrite: bool = true):
	path = _prepare_path_to_save_image(path, default_name, datetime_on_default, overwrite)
	if path.empty():
		return
	
	var error = image.save_png(path)
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
			Consts.HELP_DESC_IMAGE_SAVED, path]).execute()
	l.error(error, "Couldn't save image of name as: " + path)


func save_image_data(image_data: ImageData, path: String, default_name: String = "", 
datetime_on_default: bool = true, overwrite: bool = true):
	path = _prepare_path_to_save_image(path, default_name, datetime_on_default, overwrite)
	if path.empty():
		return
	
	var data: PoolByteArray = image_data.raw_image_data
	if data.empty():
		l.g("Can't save image data, there's no data, at path: " + path)
	
	var file: File = File.new()
	
	var error = file.open(path, File.WRITE)
	l.error(error, "Failure to open file: " + path)
	if file.is_open():
		file.store_buffer(data)
		Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
				Consts.HELP_DESC_IMAGE_SAVED, path]).execute()
		file.close()



func _prepare_path_to_save_image(path: String, default_name: String = "", 
datetime_on_default: bool = true, overwrite: bool = true, extension: String = '') -> String:
	# Will create directory if needed and return a valid path according to specifications
	
	# Properly format extension and determine if we should force extension
	extension = extension.strip_edges()
	var force_extension = not extension.empty()
	if extension.empty():
		extension = '.png'
	elif extension[0] != '.':
		extension = '.' + extension
	
	# Preparing variables: datetime, has_extension, has_name
	var dir = Directory.new()
	var file_path: String
	var counter = 0
	var dt: Array = Time.get_datetime_dict_from_system().values()
	var datetime: String = str(dt[0]).substr(2) + str_dt(dt[1]) + str_dt(dt[2]) # Ej.: 230915
	datetime += "_" # Ej.: 230915_
	datetime += str_dt(dt[5]) + str_dt(dt[6]) # Ej.: 230915_1208
	var has_extension = not path.get_file().get_extension().empty()
	var has_name = not path.get_file().get_basename().empty()
	
	# Extracting extension if it's already on the path AND there's no specific extension request
	if has_extension and not force_extension:
		extension = "." + path.get_file().get_extension()
	
	# Combining path, name and extension according to specification
	if has_extension and has_name: # if has the file name on path
		file_path = path.get_basename() + extension
	elif not default_name.empty(): # if a default image name is specified
		if datetime_on_default:
			file_path = path.get_basename().plus_file(datetime + "_" + default_name + extension)
		else:
			file_path = path.get_basename().plus_file(default_name + extension)
	elif datetime_on_default:
		file_path = path.plus_file(datetime + extension)
	else:
		l.g("Can't save image, can't determine the name. Path: " + path)
		return ''
	
	# Create directory if needed
	path = file_path.get_base_dir()
	if not dir.dir_exists(path):
		dir.make_dir_recursive(path)
	
	# Generate unique name if needed
	if not overwrite: 
		var base_file_path: String = file_path.get_basename()
		extension = "." + file_path.get_extension()
		while dir.file_exists(file_path):
			counter += 1
			file_path = base_file_path + "_" + str(counter) + extension
	
	return file_path


func str_dt(value):
	# Returns a string, but will always have a lenght of two, missing lenght
	# will be prefixed with 0. Intended for it's use in dates
	
	var resul = str(value)
	if resul.length() == 1:
		resul = '0' + resul
	
	return resul




