extends Reference

class_name ImageData

const ALLOWED_IMG_TYPES = ['png', 'jpeg', 'jpg']

enum{
	OTHER,
	PNG, 
	JPG,
	BMP,
	TGA,
	WEBP,
}

var is_ready: bool = false
var raw_image_data: PoolByteArray = PoolByteArray()
var base64: String = '' setget , get_base64
var image_extension: int
var image: Image = Image.new() 
var texture: ImageTexture = ImageTexture.new()
var path: String = ''
var image_name: String = ''
var search_data: String = ''


func _init(name: String):
	image_name = name.strip_escapes()


func set_name(name: String):
	image_name = name.strip_escapes()


func _assemble_images():
	var error
	match image_extension:
		PNG:
			error = image.load_png_from_buffer(raw_image_data)
		JPG:
			error = image.load_jpg_from_buffer(raw_image_data)
		BMP:
			error = image.load_bmp_from_buffer(raw_image_data)
		TGA:
			error = image.load_tga_from_buffer(raw_image_data)
		WEBP:
			error = image.load_webp_from_buffer(raw_image_data)
	
	if error != OK:
		l.g("Couldn't load image. Extension '" + str(image_extension) + "'. Error: " + 
		str(error) + ". Origin: " + path)
	
	texture.create_from_image(image)


func load_data(raw_image_data_: PoolByteArray, image_extension_: int):
	raw_image_data = raw_image_data_
	image_extension = image_extension_
	_assemble_images()
	is_ready = true
	return self


func load_base64(raw_image_base64: String, image_extension_: int = -1):
	if image_extension_ == -1:
		var first_char = raw_image_base64[0]
		match first_char:
			'/': 
				image_extension = JPG
			'i':
				image_extension = PNG
			'U': 
				image_extension = WEBP
			_:
				l.g("First character of base64 not resgistered, unknown image extension." +
						"Image: " + raw_image_base64.substr(0, 10) + "...")
				return null
	else:
		image_extension = image_extension_
	
	raw_image_data = Marshalls.base64_to_raw(raw_image_base64)
	_assemble_images()
	is_ready = true
	return self


func load_image_path(image_path: String):
	if is_valid_image_type(image_path):
		path = image_path
		var image_file = File.new()
		image_file.open(image_path, File.READ)
		load_data(
				image_file.get_buffer(image_file.get_len()), # byte data
				get_extension_int(image_path.get_extension())) # extension
	
	return self


func load_image_object(image_to_load: Image):
	return load_data(image_to_load.save_png_to_buffer(), PNG)


func load_texture(texture_to_load: Texture):
	return load_image_object(texture_to_load.get_data())


func is_valid_image_type(image_name_to_check: String, error_msg: bool = false) -> bool:
	var extension: String = image_name_to_check.get_extension()
	if extension.to_lower() in ALLOWED_IMG_TYPES:
		return true
	else:
		if error_msg:
			l.g("Not valid image extension '" + image_name_to_check + "'.")
		return false


static func get_extension_int(extension: String) -> int:
	var resul
	match extension.to_lower():
		'png':
			resul = PNG
		'jpeg', 'jpg':
			resul = JPG
		_: 
			resul = OTHER
	
	return resul


func get_base64() -> String:
	if base64 == null:
		if is_ready:
			base64 = Marshalls.raw_to_base64(raw_image_data)
		else:
			return ''
	
	return base64


func get_image_object() -> Image:
	if image == null:
		_assemble_images()
	
	return image


func get_image_texture() -> ImageTexture:
	if texture == null:
		_assemble_images()
	
	return texture


func get_size() -> Vector2:
	return image.get_size()


func match_string(string: String) -> bool:
	if search_data.empty():
		search_data = image_name.to_lower()
	
	string = string.to_lower()
	if string in search_data:
		return true
	elif string in image_name.to_lower():
		return true
	else:
		return false


func save(save_path: String, datetime_on_default: bool = true, overwrite: bool = true):
	ImageProcessor.save_image_data(self, save_path, image_name, datetime_on_default, overwrite)
