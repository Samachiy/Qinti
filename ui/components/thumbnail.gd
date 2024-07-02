extends TextureRect

class_name Thumbnail

var MODIFIER_NODE = load("res://ui/modifiers/modifier.tscn")

onready var menu = $"%Menu"

# MODIFIERS
# Only modifiers can be reorderes/dragged, and only when on the modifiers area.
# No animation, but on reorder, we are gonna add an empty placeholder to signal 
# that you can move it

# THUMBNAILS
# thumbnail area can't be reordered, also no animations

var modifier = null # modifier goes here, likewise, modifier will have a var
		# to place there the original or preprocessed image (to decide)


var vertical_proportion: float
var new_x_pos = 0
var new_y_pos = 0
var new_min_width = 0
var current_image_data: ImageData = null
var is_in_tree: bool = false
var pressed_left = false
var pressed_right = false


func is_match(_text: String):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'is_match' has not been overriden yet on thumbnail: " + 
	filename)
	return true


func is_named(_text: String):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'is_named' has not been overriden yet on thumbnail: " + 
	filename)
	return false


func _fill_menu():
	l.g("The function '_fill_menu' has not been overriden yet on thumbnail: " + 
	filename)


func _on_Menu_option_pressed(_label_id, _index_id):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function '_on_Menu_option_pressed' has not been overriden yet on thumbnail: " + 
	filename)


func _on_pressed():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function '_on_pressed' has not been overriden yet on thumbnail: " + 
	filename)


func _ready():
	if menu == null:
		l.g("Thumbnail '" + filename + "' does not have a menu instanced")
	else:
		menu.connect("option_selected", self, "_on_Menu_option_pressed")
		_fill_menu()
	
	is_in_tree = true
	var e = connect("tree_exiting", self, "_on_tree_exiting")
	l.error(e, l.CONNECTION_FAILED)
	e = connect("tree_entered", self, "_on_tree_entered")
	l.error(e, l.CONNECTION_FAILED)
	e = connect("gui_input", self, "_on_gui_input")


func set_image_data(image_data_: ImageData):
	current_image_data = image_data_
	texture = image_data_.texture
	var image_size: Vector2 = texture.get_size()
	#image_data_.image.save_png("user://wuttf.png")
	if image_size.x == 0:
		l.g("Image data size is 0 on thumbnail")
		vertical_proportion = 1
		return
	
	vertical_proportion = image_size.y / float(image_size.x)


func create_info_modifier():
#	_disconnect_modifier_if_needed("create_info_modifier")
	create_empty_modifier()
	if modifier != null:
		modifier.set_as_image_type(current_image_data)
		# This is so that when we remove it, another one replace it for future drag_data
#		modifier.connect("tree_exited", self, "create_info_modifier", [], CONNECT_ONESHOT)


func create_empty_modifier():
	if modifier is Node and modifier.get_parent() == self:
		modifier.queue_free()
		modifier = null
	
	if is_in_tree:
		modifier = MODIFIER_NODE.instance()
		modifier.visible = false
		add_child(modifier)
		modifier.is_in_modifier_area = false


#func _disconnect_modifier_if_needed(self_create_method: String, self_create_object: Object = self):
#	if not is_in_tree:
#		return
#
#	if modifier != null and modifier.get_parent() == self:
#		# We do this since the next create_empty_modifier() will free the current modifier and 
#		# create another, since the free() is queued, tree_exited will be activated once a new 
#		# modifier has been created, deleting the new modifier too which will call this function
#		# again, creating an infinite loop
#		# This is only assuming a new modifier is created right after the previous exits
#		# So far, this only happens in:
#		#	- thumbnail > create_info_modifier()
#		# this doesn't happen in:
#		#	- styling_thumbnail > create_style_modifier()
#		#	- preview_thumbnail > create_img2img_modifier() 
#		if modifier.is_connected("tree_exited", self_create_object, self_create_method):
#			modifier.disconnect("tree_exited", self_create_object, self_create_method)


func set_to_new_position():
	rect_position.x = new_x_pos
	rect_position.y = new_y_pos
	rect_size.x = new_min_width
	rect_size.y = vertical_proportion * rect_size.x


func get_y_end_pos():
	return rect_position.y + rect_size.y


func get_drag_data(_position: Vector2):
	var mydata = modifier
	var preview = TextureRect.new()
	preview.expand = true
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview.texture = current_image_data.texture
	preview.rect_size = rect_size
	set_drag_preview(preview)
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "set_on_top").args([preview]).execute()
	Cue.new(Consts.UI_DROP_GROUP, "enable_drop").execute()
	return mydata


func _on_tree_entered():
	is_in_tree = true


func _on_tree_exiting():
	is_in_tree = false


func _on_gui_input(event):
	if not event is InputEventMouseButton:
		return
	
	# left click
	if event.get_button_index() == BUTTON_LEFT:
		if pressed_left and not event.pressed:
			_on_pressed()
		
		pressed_left = event.pressed
	# right click
	elif event.get_button_index() == BUTTON_RIGHT:
		if pressed_right and not event.pressed:
			menu.popup_at_cursor()
		
		pressed_right = event.pressed


func prepare_to_free():
	pass
