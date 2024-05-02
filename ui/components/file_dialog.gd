extends FileDialog

const ALLOWED_IMG_TYPES = ['png', 'jpeg', 'jpg']

export(String, FILE, "*.png") var default_image = ""

var default_image_data: ImageData = null
var default_save_path: String = PCData.get_program_dir()
var default_path_changed: bool = false
var temporal_connections: Array = []

func _ready():
	Roles.request_role(self, Consts.ROLE_FILE_PICKER)
	var error = connect("popup_hide", self, "_on_popup_hide")
	l.error(error, l.CONNECTION_FAILED)
	if default_image.empty():
		default_image_data = Consts.default_image_data
	else:
		default_image_data = ImageData.new("default_image")
		default_image_data.load_image_path(default_image)
	Director.connect_global_save_cues_requested(self, "_on_global_save_cues_requested")


func get_extension_int(extension: String):
	var resul
	match extension.to_lower():
		'png':
			resul = ModifierMode.PNG
		'jpeg', 'jpg':
			resul = ModifierMode.JPG
		_: 
			resul = ModifierMode.OTHER
	
	return resul


func request_dialog(cue: Cue):
	# [requesting_node, signal_function, mode]
	# { "filter_name1": "*.ext1_1, *.ext1_2",
	#	"filter_name2": "*.ext2_1, *.ext2_2, *.ext2_3",
	#	...
	# }
	var requesting_node = cue.get_at(0, null)
	var signal_function = cue.get_at(1, '')
	var requested_mode = cue.get_at(2, MODE_OPEN_FILE)
	var filters_dict = cue._options
	var filters_parsed = []
	current_path = default_save_path
	for key in filters_dict.keys():
		filters_parsed.append(filters_dict[key] + " ; " + key)
	filters = PoolStringArray(filters_parsed) # this will also clear filters if there aren't any
	
	mode = requested_mode
	var error 
	_on_popup_hide() # We call this to clear previous requests data, just in case.
	match mode:
		MODE_OPEN_FILES:
			error = temporal_connect("files_selected", 
					requesting_node, 
					signal_function)
		MODE_OPEN_FILE:
			error = temporal_connect("file_selected", 
					requesting_node, 
					signal_function)
		MODE_SAVE_FILE:
			error = temporal_connect("file_selected", 
					self, 
					"_on_save_path_selected")
			error = temporal_connect("file_selected", 
					requesting_node, 
					signal_function)
			deselect_items()
		MODE_OPEN_DIR:
			filters = PoolStringArray([])
			error = temporal_connect("dir_selected", 
					requesting_node, 
					signal_function)
	popup_centered_ratio(0.8)
	deselect_items()
	l.error(error, "Couldn't open file dialog. Request data: " + 
			str(requesting_node) + " " + 
			str(signal_function) + ". Mode:" +
			str(requested_mode)
		)


func temporal_connect(signal_name: String, object: Object, method: String):
	temporal_connections.append([signal_name, object, method]) 
	return connect(signal_name, object, method, [], CONNECT_ONESHOT)


func get_file_clusters(cue: Cue):
	# [ path, default_image_data: ImageData ]
	var path: String = cue.str_at(0, '')
	var image_data: ImageData = cue.get_at(1, default_image_data, false)
	return _get_file_clusters_at(path, image_data)


func thread_get_file_clusters(cue: Cue) -> Thread:
	# [ path, receiving_object, receiving_method, default_image_data: ImageData ]
	var thread: Thread = Thread.new()
	var error = thread.start(self, "_get_send_file_clusters", cue)
	l.error(error, "Couldn't start thread to read file clusters. Args: " + str(cue._arguments))
	return thread


func _get_send_file_clusters(cue: Cue):
	# [ path, receiving_object, receiving_method, default_image_data: ImageData ]
	var path: String = cue.str_at(0, '')
	var receiving_obj = cue.object_at(1, null)
	var receiving_method = cue.str_at(2, '')
	var image_data: ImageData = cue.get_at(3, default_image_data, false)
	
	if receiving_obj == null:
		l.g("Can't retrieve threaded file clusters, receiving object is null, at: " + path)
		if receiving_obj.has_method(receiving_method):
			receiving_obj.call_deferred(receiving_method, [])
		return
	
	if receiving_method.empty():
		l.g("Can't retrieve threaded file clusters, receiving method is empty, at: " + path)
		if receiving_obj.has_method(receiving_method):
			receiving_obj.call_deferred(receiving_method, [])
		return
	
	if receiving_obj.has_method(receiving_method):
		var clusters = _get_file_clusters_at(path, image_data)
		receiving_obj.call_deferred(receiving_method, clusters)
	else:
		l.g("Can't retrieve threaded file clusters. Receiving object lacks method: " + 
				receiving_method)


func _get_file_clusters_at(path: String, image_data: ImageData, clusters: Dictionary = {}) -> Dictionary:
	var dir: Directory = Directory.new()
	var error = safe_open_dir(path, dir, false)
	l.error(error, "No folder found to load file_clusters at: " + path)
	if error != OK:
		return clusters
	
	error = dir.list_dir_begin(true, true)
	l.error(error, "Failure to list firectories to load file_clusters at: " + path)
	if error != OK:
		return clusters
	
	var file_name = dir.get_next()
	var cluster: FileCluster = null
	while file_name != "":
		if dir.current_is_dir():
# warning-ignore:return_value_discarded
			_get_file_clusters_at(path.plus_file(file_name), image_data, clusters)
		else:
			cluster = clusters.get(path.plus_file(file_name.get_basename()), null)
			if cluster == null:
				cluster = FileCluster.new(path, image_data)
				clusters[path.plus_file(file_name.get_basename())] = cluster
			
			cluster.add_file(file_name)
		
		file_name = dir.get_next()
	
	return clusters


func get_file_paths(cue: Cue) -> Array:
	# [ path, filter1, filter2, ... ]
	var path: String = cue.str_at(0, '')
	var filter_ext: Array = []
	var extension
	
	for i in range(1, cue._arguments.size()):
		extension = cue._arguments[i]
		if extension is String:
			extension = extension.replace(".", "")
			filter_ext.append(extension)
	
	return _get_file_paths_at(path, filter_ext)


func _get_file_paths_at(path: String, filter_ext: Array, result: Array = []):
	# [ path, filter1, filter2, ... ]
	var dir: Directory = Directory.new()
	var error = safe_open_dir(path, dir, false)
	
	l.error(error, "No folder found to load file_clusters at: " + path)
	if error != OK:
		return []
	
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
# warning-ignore:return_value_discarded
			_get_file_paths_at(path.plus_file(file_name), filter_ext)
		else:
			if file_name.get_extension() in filter_ext:
				result.append(path.plus_file(file_name))
		
		file_name = dir.get_next()
	
	return result


func safe_open_dir(path: String, dir: Directory, create: bool = true) -> int:
	# returns Error
	var error
	if not dir.dir_exists(path) and create:
		error = dir.make_dir_recursive(path)
		l.error(error, "Couldn't create recursively path: " + path)
	
	error = dir.open(path)
	dir.list_dir_begin(true, true)
	return error


func _on_save_path_selected(path: String):
	default_save_path = path.get_base_dir().plus_file('')
	default_path_changed = true


func get_default_save_path(_cue: Cue = null):
	return default_save_path


func set_default_save_path(cue: Cue):
	var path: String = cue.str_at(0, '')
	if path.empty():
		return
	
	_on_save_path_selected(path)


func _on_popup_hide():
	for signal_data in temporal_connections:
		# signal_data: [signal_name, object, method]
		if is_connected(signal_data[0], signal_data[1], signal_data[2]):
			disconnect(signal_data[0], signal_data[1], signal_data[2])
	
	temporal_connections.clear()


func _on_global_save_cues_requested():
	if default_path_changed:
		Director.add_global_save_cue(
				Consts.ROLE_FILE_PICKER, 
				"set_default_save_path", 
				[default_save_path])
