extends VBoxContainer

onready var image = $Viewer/Photo/Image
onready var image_frame = $Viewer/Photo
onready var description = $Viewer/Details/Description
onready var edit_controls = $EditControls

export(bool) var readonly_prompt = false
export(bool) var show_preview = true
export(bool) var show_description = true

var file_cluster: FileCluster = null
var new_image: ImageData = null

signal close_requested

func _ready():
	image_frame.visible = show_preview


func set_data(file_cluster_: FileCluster):
	file_cluster = file_cluster_
	description.text = file_cluster.get_txt_data()
	new_image = null
	image.texture = get_image_data().texture


func save_data():
	if description.text.empty() and file_cluster.description_file.empty():
		# if description is empty and there's no previous file, there's no point of writing
		# the description file for it will be just empty. It there was a previous file,
		# at the very list we could be erasing the data clean, but there isn't
		pass
	else:
		file_cluster.save_text(description.text)
	
	if new_image != null:
		if new_image == Consts.default_image_data:
			file_cluster.delete_png()
		else:
			file_cluster.save_png(new_image)
		
		file_cluster.refresh_image_data()


func refresh_image():
	var image_data = get_image_data()
	if image_data is ImageData:
		image.texture = image_data.texture


func get_image_data() -> ImageData:
	return file_cluster.get_image_data()


func clear():
	description.text = ''


func _on_DropArea_modifier_dropped(_position, modifier):
	if modifier is Modifier:
		new_image = modifier.image_data
		image.texture = new_image.texture


func _on_DropArea_file_cluster_dropped(_position, dropped_file_cluster):
	if dropped_file_cluster is FileCluster:
		new_image = dropped_file_cluster.get_image_data()
		image.texture = new_image.texture


func _on_DropArea_image_data_dropped(_position, image_data):
	if image_data is ImageData:
		new_image = image_data
		image.texture = new_image.texture


func _on_Save_pressed():
	save_data()


func _on_Cancel_pressed():
	emit_signal("close_requested")
