extends HBoxContainer

onready var label = $Label
onready var checkbox = $CheckBox

enum {
	GENERATION,
	SETTING,
	MODEL,
	SIZE,
	DISABLED,
}

var config_key: String = ''
var config_value = ''
var type: int = GENERATION
var config: Dictionary = {}
var disabled: bool = false

signal display_info_requested(info)

func _ready():
	var error = UIOrganizer.connect("locale_changed", self, "update_label")
	l.error(error, l.CONNECTION_FAILED)
	update_label()


func update_label(_locale = null):
	label.text = tr(config_key) + ": " + str(config_value) # donetr


func disable():
	checkbox.pressed = false
	checkbox.disabled = true


func select():
	checkbox.pressed = true


func deselect():
	checkbox.pressed = false


func is_selected() -> bool:
	return checkbox.pressed


func set_selected(selected: bool):
	checkbox.pressed = selected


func set_as_disabled_detail(detail_name: String, detail_value: String):
	config_key = detail_name.to_upper() 
	# detail_name is already uppercase, this is done just in case
	
	config_value = detail_value
	update_label()
	config.clear()
	type = DISABLED
	disabled = true
	checkbox.pressed = false
	checkbox.disabled = true
	checkbox.visible = false


func set_as_generation_detail(detail_name: String, detail_value):
	config_key = detail_name.to_upper() 
	# detail_name is already uppercase, this is done just in case
	
	config_value = detail_value
	update_label()
	config.clear()
	type = GENERATION
	config[detail_name] = detail_value


func set_as_setting_detail(detail_name: String, detail_value: String):
	config_key = detail_name.to_upper()
	# detail_name is already uppercase, this is done just in case
	
	config_value = detail_value
	update_label()
	config.clear()
	type = SETTING


func set_as_model_detail(detail_name: String, detail_value: String, model_hash: String):
	config_key = detail_name.to_upper()
	# detail_name is already uppercase, this is done just in case
	
	config.clear()
	type = MODEL
	if detail_value.empty():
		config[Consts.SDO_MODEL_HASH] = model_hash
		config_value = model_hash
	else:
		config[Consts.SDO_MODEL] = detail_value
		config_value = detail_value
	
	update_label()


func set_as_size_detail(detail_name: String, detail_value: String):
	config_key = detail_name.to_upper()
	# detail_name is already uppercase, this is done just in case
	
	config_value = detail_value
	update_label()
	config.clear()
	type = SIZE
	var size_vec = detail_value.split('x', false)
	if size_vec.size() >= 2:
		config[Consts.I_WIDTH] = int(size_vec[0])
		config[Consts.I_HEIGHT] = int(size_vec[1])
	else:
		disable()


func append_if_checked(dictionary: Dictionary):
	if checkbox.disabled or not checkbox.pressed or disabled:
		return
	
	append(dictionary)


func append(dictionary: Dictionary):
	if disabled:
		return
	
	var aux
	match type:
		GENERATION, SIZE:
			dictionary.merge(config)
		SETTING, MODEL:
			aux = dictionary.get(Consts.I_OVERRIDE_SETTINGS)
			if aux == null:
				aux = {}
				dictionary[Consts.I_OVERRIDE_SETTINGS] = aux
			aux.merge(config)


func connect_detail(object: Object, method: String):
# warning-ignore:return_value_discarded
	 connect("display_info_requested", object, method)


func _on_Label_pressed():
	emit_signal("display_info_requested", config_value)
