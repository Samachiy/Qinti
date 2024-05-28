extends Thumbnail

class_name FileClusterThumbnail

onready var label = $"%ThumbnailName"
onready var label_bg = $"%ThumbnailNameBG"

var is_default_image: bool = false
var file_cluster: FileCluster = null


func _ready():
	label_bg.modulate.a8 = Consts.LABEL_FONT_COLOR_INVERSE_A
	UIOrganizer.add_to_theme_by_modulate_group(label_bg, Consts.THEME_MODULATE_GROUP_TYPE)
	label.connect("resized", self, "_on_Label_resized")


func set_cluster(new_file_cluster: FileCluster):
	clear_cluster()
	file_cluster = new_file_cluster
	var e = file_cluster.connect("image_data_refreshed", self, "_refresh_image_data_with")
	l.error(e, l.CONNECTION_FAILED)
	var image_data = file_cluster.get_image_data()
	_refresh_image_data_with(image_data)
	set_label(file_cluster.name)


func is_match(text: String):
	if text.empty():
		return true
	else:
		return file_cluster.match_string(text)


func is_q_hash_match(text: String):
	if text.empty():
		return true
	else:
		return file_cluster.match_q_hash(text)


func clear_cluster():
	if file_cluster == null:
		return
	
	if file_cluster.is_connected("image_data_refreshed", self, "_refresh_image_data_with"):
		file_cluster.disconnect("image_data_refreshed", self, "_refresh_image_data_with")


func set_label(text: String):
	label.text = text.strip_edges()


func _refresh_image_data_with(image_data: ImageData):
	if image_data == null:
		image_data = file_cluster.default_image_data
	
	if image_data == Consts.default_image_data:
		is_default_image = true
	else:
		is_default_image = false
		
	set_image_data(image_data)
	_on_Label_resized()


func _on_Label_resized():
	yield(get_tree(), "idle_frame")
	
	if is_default_image:
		label_bg.color.a8 = 225
		label.rect_position.y = 0
		label.rect_size.y = rect_size.y
		label.autowrap = true
		label.align = label.ALIGN_CENTER
		label.valign = label.VALIGN_CENTER
		label.clip_text = false
	else:
		label_bg.color.a8 = 190
		label.autowrap = false
		label.align = label.ALIGN_LEFT
		label.valign = label.VALIGN_BOTTOM
		label.clip_text = true
		if label.rect_position.y <= 0:
			label.rect_size.y = 0
			yield(get_tree(), "idle_frame")
			label.rect_position.y = rect_size.y - label.rect_size.y

