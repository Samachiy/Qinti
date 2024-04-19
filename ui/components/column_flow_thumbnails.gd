extends Container

var number_of_columns: int = 2
var image_spacing: int = 15

var thumbnail_packed_scene
var image_width: int = 0
var thumbnails_order: Array = [] # this refers to the order in the columns
var temp_children: Array = []
var thumbnails_loaded: bool = false
var contained_clusters: Dictionary = {}


func _ready():
	yield(get_tree().current_scene, "ready")
	_on_ColumnFlowContainer_resized()


func load_images_from_folder(path: String):
	thumbnails_loaded = true
	#l.start_measure()
	var image_list: Array = []
	var image_dir = Directory.new()
	image_dir.open(path)
	image_dir.list_dir_begin(true)
	var file_name: String = image_dir.get_next()
	while not file_name.empty():
		file_name = image_dir.get_next()
		if '.png' in file_name:
			image_list.append(file_name)
	
	var new_thumbnail
	for image_name in image_list:
		if not _is_valid_image_type(image_name):
			continue
		
		
		new_thumbnail = create_thumbnail()
		var image_data = ImageData.new(image_name).load_image_path(path + image_name)
		new_thumbnail.set_image_data(image_data)
		new_thumbnail.create_info_modifier()
	
	thumbnails_order = sort_thumbnail_in_columns()
	#l.write_measure("thumbnails loaded")
	place_thumbnails(thumbnails_order)


func load_file_clusters(clusters: Dictionary, styling_format: String):
	thumbnails_loaded = true
	var new_thumbnail
	for cluster in clusters.values():
		if cluster.main_file.empty():
			continue
		
		contained_clusters[cluster.path.plus_file(cluster.name)] = cluster
		new_thumbnail = create_thumbnail(false)
		if not new_thumbnail is FileClusterThumbnail:
			l.g("Wrong thumbnail type, can't load file clusters at: " + get_path())
		
		new_thumbnail.set_cluster(cluster)
		if not styling_format.empty():
			new_thumbnail.set_styling_data(styling_format)
	
	refresh_order()


func refresh_order():
	thumbnails_order = sort_thumbnail_in_columns()
#	place_headers()
	place_thumbnails(thumbnails_order)


func clear():
	for child in temp_children:
		if is_instance_valid(child):
			child.queue_free()
	
	temp_children.clear()
	contained_clusters.clear()


func create_thumbnail(set_as_first: bool = true):
	var new_thumbnail = thumbnail_packed_scene.instance()
	add_child(new_thumbnail)
	temp_children.append(new_thumbnail)
	if set_as_first:
		move_child(new_thumbnail, 0)
	return new_thumbnail


func _is_valid_image_type(image_name: String):
	var extension_pos = image_name.rfind(".")
	var extension = image_name.substr(extension_pos + 1)
	if extension in ImageData.ALLOWED_IMG_TYPES:
		return true
	else:
		return false


func place_thumbnails(thumbnails_per_column: Array):
	var thumbnail: TextureRect
	var image_pos_y = 0
	var image_pos_x = 0
	var max_size = 0
	for thumbnails in thumbnails_per_column:
		for i in range(thumbnails.size()):
			thumbnail = thumbnails[i]
			thumbnail.new_x_pos = image_pos_x
			thumbnail.new_y_pos = image_pos_y
			thumbnail.new_min_width = image_width
			thumbnail.set_to_new_position()
			image_pos_y += round(thumbnail.vertical_proportion * image_width + image_spacing)
		
		if image_pos_y > max_size:
			max_size = image_pos_y
		
		image_pos_y = 0
		image_pos_x += image_width + image_spacing
	
	rect_min_size.y = max_size


func sort_thumbnail_in_columns() -> Array:
	# this will hold the curent size of each columns
	var columns_size := Array() 
	columns_size.resize(number_of_columns)
	columns_size.fill(0.0)
	
	# this will hold arrays with the thumbnail node that go into each column
	var columns_nodes := Array() 
	columns_nodes.resize(number_of_columns)
	for i in range(columns_nodes.size()):
		columns_nodes[i] = Array()
	
	var choosen_column: int
	for child in get_children():
		if not is_instance_valid(child):
			continue
		
		if child.is_queued_for_deletion():
			continue
		
		if not child.visible:
			continue
		
		if child is Thumbnail:
			choosen_column = _get_lowest_array_element(columns_size)
			columns_size[choosen_column] += child.vertical_proportion
			columns_nodes[choosen_column].append(child)
	
	if number_of_columns == 5:
		pass
	return columns_nodes


func show_only_thumbnail_matches(match_string: String):
	for child in get_children():
		if not is_instance_valid(child):
			continue
		
		if child.is_queued_for_deletion():
			continue
		
		if child is Thumbnail:
			child.visible = child.is_match(match_string)


func _get_lowest_array_element(column_sizes: Array) -> int:
	var min_size = column_sizes[0]
	var min_element = 0
	for i in range(1, column_sizes.size()):
		if column_sizes[i] < min_size:
			min_size = column_sizes[i]
			min_element = i
	
	return min_element


func _on_ColumnFlowContainer_resized():
	var total_image_spacing = image_spacing * (number_of_columns - 1)
	var new_width = int((rect_size.x - total_image_spacing) / number_of_columns)
	if new_width != image_width:
		image_width = new_width
		place_thumbnails(thumbnails_order)

