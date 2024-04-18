extends VBoxContainer

class_name VFlowClusters

const SEARCH_DELAY = 0.3

onready var controls = $Controls
onready var styles_types = $OptionButton
onready var search_bar = $Controls/SearchBar
onready var search_timer = $Controls/SearchBar/SearchTimer
onready var refresh_button = $Controls/Refresh
onready var external_button = $Controls/ExternalPath
onready var container = $ScrollContainer/ColumnFlowContainer

export(String, FILE, "*.tscn") var thumbnail_node = "res://ui/components/thumbnail.tscn"
export(Resource) var categories = null
export var number_of_columns: int = 2
export var image_spacing: int = 10
export var add_refresh_button: bool = true
export var add_external_button: bool = true

signal refresh_requested
signal external_path_requested
signal container_selected

func _ready():
	if categories is ThumbnailCategories:
		yield(get_parent(), "ready")
		categories.fill_combobox(styles_types, '')
	else:
		styles_types.visible = false
	
	# We connect this via code since styles_types script is marked as tool
	# which will spam the output console of the IDE if connected before execution
	var error = styles_types.connect("resized", self, "_on_OptionButton_resized")
	l.error(error, l.CONNECTION_FAILED)
	
	container.thumbnail_packed_scene = load(thumbnail_node)
	container.number_of_columns = number_of_columns
	container.image_spacing = image_spacing
	
	search_timer.wait_time = SEARCH_DELAY
	refresh_button.visible = add_refresh_button
	external_button.visible = add_external_button


func clear_search():
	search_bar.text = ''
	_on_SearchTimer_timeout()


func create_thumbnail(set_as_first: bool = true):
	return container.create_thumbnail(set_as_first)


func _on_SearchBar_text_changed(_new_text):
	search_timer.start()


func _on_SearchTimer_timeout():
	var search_text = search_bar.text
	container.show_only_thumbnail_matches(search_text)
	search_timer.stop()
	container.refresh_order()


func _on_OptionButton_option_selected(option_label, _id):
	var styles_type_node = get_parent().get_node_or_null(option_label)
	if styles_type_node == null:
		l.g("The styles type '" + option_label + "' is not on the type list.")
		return
	
	if styles_type_node == self:
		visible = true
		emit_signal("container_selected")
	else:
		visible = false
		# This line makes the selected column_flow_thumbnails to select itself without
		# entring in an infinite loop since when it selects itself, styles_type_node == self
		# thus entering in the if above rather than calling select_by_label again.
		styles_type_node.styles_types.select_by_label(styles_type_node.name)


func _on_OptionButton_resized():
	yield(get_tree(), "idle_frame")
	# This if is in order to prevent the program from entreing into an infinite loop
	# since changing the rect_min_size will call this function again
	if refresh_button.rect_min_size.x != refresh_button.rect_size.y: 
		refresh_button.rect_min_size.x = refresh_button.rect_size.y


func _on_Refresh_pressed():
	emit_signal("refresh_requested")


func clear():
	container.clear()


func refresh_order():
	container.refresh_order()


func load_file_clusters(clusters: Dictionary, styling_format: String):
	container.load_file_clusters(clusters, styling_format)


func get_clusters():
	return container.contained_clusters


func get_items():
	return container.temp_children


func _on_ClearText_pressed():
	clear_search()


func _on_ExternalPath_pressed():
	emit_signal("external_path_requested")
