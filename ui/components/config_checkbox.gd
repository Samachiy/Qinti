extends CheckBox

class_name ConfigCheckBox

export(bool) var requieres_flag: bool = true
export(String) var flag_name_const = ""
export(NodePath) var flag_prefix_node_name: NodePath
export(bool) var is_global_flag = true

# this flag is also the default name for the setting, so we can use it to build 
# the config dictionaries that the api uses
var flag: Flag = null 


func _ready():
	var error = connect("toggled", self, "_on_config_checkbox_toggled")
	l.error(error, l.CONNECTION_FAILED)
	if flag_name_const == "":
		if requieres_flag:
			l.g("Checkbox does not have a flag assigned at: " + get_path())
	else:
		add_to_group(Consts.UI_UPDATE_FLAG_ON_LOAD_GROUP)
		Director.connect_global_file_loaded(self, "_on_global_file_loaded")


func _on_global_file_loaded():
	update_with_flag()


func update_with_flag(_cue: Cue = null):
	if flag == null or not flag.exists():
		var flag_name = Consts.get(flag_name_const)
		if flag_name == null:
			l.g("Checkbox has a flag not registered in consts assigned at: " + get_path())
			return
		
		if not flag_prefix_node_name.is_empty():
			var prefix_node = get_node_or_null(flag_prefix_node_name)
			if prefix_node != null:
				flag_name = prefix_node.name + "_" + flag_name
		
		flag = Flags.ref(flag_name)
		flag.set_up(is_global_flag, null, null, get_value())
	
	if flag.value == 0:
		pressed = false
	else:
		pressed = true


func get_value():
	if pressed:
		return 1
	else:
		return 0


func _on_config_checkbox_toggled(toggled):
	if flag == null:
		return
	
	if toggled:
		flag.value = 1
	else:
		flag.value = 0


func add_config_to_dict(dictionary: Dictionary):
	if flag != null:
		dictionary[flag.name] = pressed
