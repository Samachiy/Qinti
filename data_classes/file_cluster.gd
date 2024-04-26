extends Reference

class_name FileCluster

var main_file: String = '' # path of .safetensors, .ckpt, .pt or .pth
var main_count: int = 0
var image_file: String = ''  # path of .png, .jpeg, .jpg, etc (see image data types)
var image_count: int = 0
var description_file: String = '' # path of .txt
var metadata_file: String = '' # path of .json
var image_extensdion: int = -1
var image_data: ImageData = null
var name: String = ''
var search_data: String = ''
var path: String = ''
var default_image_data: ImageData = null

signal image_data_refreshed(image_data)

func _init(directory: String, default_image_data_: ImageData):
	default_image_data = default_image_data_
	path = directory


func add_file(file_path: String):
	var extension = file_path.get_extension().to_lower()
	match extension:
		'safetensors':
			# safetensors takes priority over other formats
			main_count += 1
			main_file = file_path
		'ckpt', 'pt', 'pth':
			main_count += 1
			if main_file.empty():
				main_file = file_path
		'png':
			# png takes priority over other formats
			image_count = 0
			image_file = file_path
			image_extensdion = ImageData.get_extension_int(extension)
		'jpeg', 'jpg':
			image_count = 0
			if image_file.empty():
				image_file = file_path
		'txt':
			description_file = file_path
		'json':
			metadata_file = file_path
		_:
			pass
	
	if name.empty():
		name = file_path.get_basename()


func get_file_path():
	if main_file.empty():
		return ''
	else:
		return path.plus_file(main_file)


func get_json_path():
	if metadata_file.empty():
		return path.plus_file(name + ".json")
	else:
		return path.plus_file(metadata_file)


func get_txt_path():
	if description_file.empty():
		return path.plus_file(name + ".txt")
	else:
		return path.plus_file(description_file)


func get_png_path():
	if image_file.empty():
		return path.plus_file(name + ".png")
	elif image_file.get_extension().to_lower() != "png": # if not png format
		return path.plus_file(name + ".png")
	else:
		return path.plus_file(image_file)


func get_image_path():
	if image_file.empty():
		return path.plus_file(name + ".png")
	else:
		return path.plus_file(image_file)


func get_txt_data() -> String:
	if description_file.empty():
		return ''
	
	var file = File.new()
	var txt_path = get_txt_path()
	if file.file_exists(txt_path):
		file.open(txt_path, File.READ)
		var data = file.get_as_text()
		return data
	else:
		return ''


func get_json_data() -> Dictionary:
	if metadata_file.empty():
		return {}
	
	var file = File.new()
	var json_path = get_json_path()
	if file.file_exists(json_path):
		file.open(json_path, File.READ)
		var data = parse_json(file.get_as_text())
		if data is Dictionary:
			return data
		else:
			return {}
	else:
		return {}


func _to_string():
	var string = main_file + " - Main: " + str(main_count) + ", Img: " + str(image_count)
	if not description_file.empty():
		string += ", description"
	
	if not metadata_file.empty():
		string += ", metadata"
	
	return string


func match_string(string: String) -> bool:
	if main_file.empty():
		return false
	
	if search_data.empty():
		search_data = name.to_lower()
	
	if string.to_lower() in search_data:
		return true
	else:
		return false


func get_image_data() -> ImageData:
	if image_data == null:
		if not image_file.empty():
			image_data = ImageData.new(name)
			image_data.load_image_path(path.plus_file(image_file))
		else:
			image_data = null
	
	if image_data == null:
		return default_image_data
	else:
		return image_data


func refresh_image_data(fill_png_if_empty: bool = true):
	if fill_png_if_empty and image_file.empty():
		var png_file_path = path.plus_file(name + ".png")
		var png_file = File.new()
		if png_file.file_exists(png_file_path):
			image_file = name + ".png"
	
	if not image_file.empty():
		image_data = ImageData.new(name)
		image_data.load_image_path(path.plus_file(image_file))
		emit_signal("image_data_refreshed", get_image_data())


func save_json(json_data_to_save):
	var file = File.new()
	metadata_file = get_json_path().get_file()
	file.open(get_json_path(), File.WRITE)
	file.store_string(to_json(json_data_to_save))
	file.close()


func save_text(text_to_save: String):
	var file = File.new()
	description_file = get_txt_path().get_file()
	file.open(get_txt_path(), File.WRITE)
	file.store_string(text_to_save)
	file.close()


func save_png(image_data_to_save: ImageData):
	var error = image_data_to_save.image.save_png(get_png_path())
	l.error(error, "Couldn't save image of name: " + get_png_path())
