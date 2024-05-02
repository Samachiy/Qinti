extends Node

class_name ModifierMode

export(Resource) var type
export(String, MULTILINE) var feature_tags
var image_data: ImageData = null
var selected = false
var data_cue: Cue = null
var mode_text: String = ''
var active_image: Image = null
var active_image_data: ImageData = null
var restore_image_data: ImageData = null
var is_prepared: bool = false
var tags: Dictionary = {} # The feature name is the key, the translation key error msg is the value

signal mode_loaded(mode_node)


func select_mode():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'select_mode' has not been overriden yet on modifier mode: " + 
	name)

func deselect_mode():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'deselect_mode' has not been overriden yet on modifier mode: " + 
	name)

func prepare_mode():
	# This function will be called more times on it's lifespan, program it accordingly
	# Called when changed the type on the modifier dropbox
	# Make sure to set the is_prepared to true
	l.g("The function 'prepare_mode' has not been overriden yet on modifier mode: " + 
	name)

func apply_to_api(_api):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'apply_to_api' has not been overriden yet on modifier mode: " + 
	name)

func clear_board():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'clear_board' has not been overriden yet on modifier mode: " + 
	name)


func _on_same_type_modifier_toggled():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function '_on_same_type_modifier_toggled' has not been overriden yet " + 
			"on modifier mode: " + name)


func get_active_image():
	# This function will be called more times on it's lifespan, program it accordingly
	# This function has to return an ImageData object
	l.g("The function 'get_active_image' has not been overriden yet on modifier mode: " + 
	name)
	

func _ready():
	var text_value =  type.types.get(name)
	if text_value == null:
		l.g("The mode '" + name + "' is not on the type list.")
	else:
		mode_text = text_value
	
	feature_tags.replace(",", "\n")
	var feature_array = feature_tags.split("\n", false)
	for feature in feature_array:
		feature = feature.strip_edges()
		if not feature.empty():
			add_feature_tag(feature)
	
	if owner is Modifier:
# warning-ignore:return_value_discarded
		connect("mode_loaded", owner, "_on_mode_loaded")


func add_feature_tag(tag_name):
	if not tag_name is String:
		l.g("Failure adding feature tag, no tag name, in: " + name)
		return
	
	tags[tag_name] = true # We just need to feel somwething, anything


func set_in_combobox(smart_option_button: Control, refill_combobox: bool):
	if refill_combobox:
		type.fill_combobox(smart_option_button, name)
	


func set_image_data(image: ImageData):
	image_data = image


func get_active_image_data():
	if active_image_data is ImageData:
		return active_image
	elif active_image is Image:
		return ImageData.new("active_image_" + name).load_image_object(active_image)
	else:
		l.g("Can't retrieve active image data, no active image was found either, at modifier: " 
				+ name)
		return null


func load_mode():
	if mode_text.empty():
		l.g("The mode '" + name + "' is not on the type list." + 
		name)
	else:
		emit_signal("mode_loaded", self)
