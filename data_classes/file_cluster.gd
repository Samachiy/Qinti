extends Reference

class_name FileCluster

const HASH = "hash"
const Q_HASH = "q_hash"

var main_file: String = '' # path of .safetensors, .ckpt, .pt or .pth
var main_count: int = 0
var alt_mains: Array = []
var image_file: String = ''  # path of .png, .jpeg, .jpg, etc (see image data types)
var image_count: int = 0
var description_file: String = '' # path of .txt
var metadata_file: String = '' # path of .json
var image_extension: int = -1
var image_data: ImageData = null
var name: String = ''
var search_data: String = ''
var path: String = ''
var default_image_data: ImageData = null
var main_file_hash: String = ""
var main_file_q_hash: String = ""

signal image_data_refreshed(image_data)

func _init(directory: String, default_image_data_: ImageData):
	default_image_data = default_image_data_
	path = directory


func clear():
	# Clears the contained files info without deleting the connected signals
	alt_mains = []
	main_count = 0
	main_file = ''
	main_file_hash = ''
	main_file_q_hash = ''
	image_count = 0
	image_file = ''
	image_extension = -1
	image_data = null
	description_file = ''
	metadata_file = ''
	name = ''
	search_data = ''


func add_file(file_path: String):
	var extension = file_path.get_extension().to_lower()
	match extension:
		'safetensors':
			# safetensors takes priority over other formats
			main_count += 1
			main_file = file_path
			get_q_hash()
		'ckpt', 'pt', 'pth':
			main_count += 1
			if main_file.empty():
				main_file = file_path
				get_q_hash()
			else:
				alt_mains.append(file_path)
				l.g("Files without disctintive name where detected, please change the name " + 
						"or remove redundant files: " + main_file + str(alt_mains), l.WARNING)
		'png':
			# png takes priority over other formats
			image_count += 1
			image_file = file_path
			image_extension = ImageData.get_extension_int(extension)
		'jpeg', 'jpg':
			image_count += 1
			if image_file.empty():
				image_file = file_path
		'txt':
			description_file = file_path
		'json':
			metadata_file = file_path
			var json_data: Dictionary = get_json_data()
			main_file_hash = json_data.get(HASH, "")
			main_file_q_hash = json_data.get(Q_HASH, "")
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


func get_q_hash():
	if main_file.empty():
		return ''
	
	if main_file_q_hash.empty():
		main_file_q_hash = HashCalculator.quick_hash_file(path.plus_file(main_file))
		return main_file_q_hash
	else:
		return main_file_q_hash


func get_hash(force: bool = false) -> String:
	if main_file.empty():
		return ''
	
	if main_file_hash.empty():
		if force:
			main_file_hash = HashCalculator.hash_file(path.plus_file(main_file))
			save_hashes()
			return main_file_hash
		else:
			l.g("Hash was requested but calculation hasn't been done before. File: " 
					+ main_file)
			return ''
	else:
		return main_file_hash


func solve_hash(fast_queue: bool):
	if main_file.empty():
		return
	
	get_q_hash()
	var main_file_path = path.plus_file(main_file)
	if main_file_hash.empty():
		if fast_queue:
			HashCalculator.hash_file_thread(main_file_path, self, "_on_hash_solved", false)
		else:
			HashCalculator.hash_file_fast_thread(main_file_path, self, "_on_hash_solved", false)


func _on_hash_solved(new_hash: String):
	main_file_hash = new_hash
	save_hashes()


func _to_string():
	var string = main_file + " - Main: " + str(main_count) + ", Img: " + str(image_count)
	if not description_file.empty():
		string += ", description"
	
	if not metadata_file.empty():
		string += ", metadata"
	
	string += "QHash: " + get_q_hash()
	
	return string


func match_string(string: String) -> bool:
	if main_file.empty():
		return false
	
	string = string.strip_edges()
	if string.empty():
		return true
	
	if search_data.empty():
		search_data = name.to_lower()
	
	if string.to_lower() in search_data:
		return true
	else:
		return false


func match_name(string: String) -> bool:
	if main_file.empty():
		return false
	
	return name == string


func get_image_data() -> ImageData:
	prepare_image_data()
	
	if image_data == null:
		return default_image_data
	else:
		return image_data


func prepare_image_data():
	if image_data != null:
		return
	
	if not image_file.empty():
		image_data = ImageData.new(name)
		image_data.load_image_path(path.plus_file(image_file))
		emit_signal("image_data_refreshed", image_data)
	else:
		image_data = null
	


func match_q_hash(q_hash: String):
	if main_file_q_hash == q_hash:
		return true
	elif alt_mains.empty():
		return false
	
	# if we DO have alternate files and haven't reached a conclusion yet
	for file_name in alt_mains:
		if HashCalculator.quick_hash_file(path.plus_file(file_name)) == q_hash:
			return true
	
	return false


func match_hash(sha256_hash: String):
	# The SHA256 hash is just here for download purposes in Civitai
	# which means that if we requiere to use this function, we need to improve the 
	# calculation method of quick hash. There are other checks for repeated
	# quick hashes, so this function is just here as backup in the worst case scenario
	if main_file_hash.empty():
		main_file_hash = HashCalculator.hash_file(path.plus_file(main_file))
		return main_file_hash == sha256_hash
	elif main_file_hash == sha256_hash:
		return true
	
	# Because of how resource intensive is to calculate sha256_hash of large files
	# we are gonna end it there
	pass


func refresh_image_data(fill_png_if_empty: bool = true):
	if fill_png_if_empty and image_file.empty():
		var png_file_path = path.plus_file(name + ".png")
		var png_file = File.new()
		if png_file.file_exists(png_file_path):
			image_file = name + ".png"
	
	
	if not image_file.empty():
		var dir = Directory.new()
		if not dir.file_exists(path.plus_file(image_file)):
			image_file = ''
			emit_signal("image_data_refreshed", get_image_data())
		else:
			image_data = ImageData.new(name)
			image_data.load_image_path(path.plus_file(image_file))
			emit_signal("image_data_refreshed", get_image_data())


func save_hashes():
	if main_file_hash.empty():
		return
	
	var data_dict: Dictionary = get_json_data()
	data_dict[HASH] = main_file_hash
	data_dict[Q_HASH] = main_file_q_hash
	save_json(data_dict)


func save_json(json_data_to_save: Dictionary):
	var file = File.new()
	metadata_file = get_json_path().get_file()
	file.open(get_json_path(), File.WRITE)
	file.store_string(to_json(json_data_to_save))
	file.close()


func save_text(text_to_save: String):
	if text_to_save.strip_edges().empty():
		delete_text()
		return
	
	var file = File.new()
	description_file = get_txt_path().get_file()
	file.open(get_txt_path(), File.WRITE)
	file.store_string(text_to_save)
	file.close()


func delete_text():
	var dir = Directory.new()
	dir.remove(get_txt_path())


func save_png(image_data_to_save: ImageData):
	var error = image_data_to_save.image.save_png(get_png_path())
	l.error(error, "Couldn't save image of name: " + get_png_path())


func delete_png():
	var error = OS.move_to_trash(PCData.globalize_path(get_png_path()))
	l.error(error, "Failure to move to trash image file: " + get_png_path(), l.WARNING)

	
