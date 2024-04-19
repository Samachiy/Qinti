extends TextureButton

class_name ConfigToggleButton

export(bool) var requieres_flag: bool = true
export(String) var flag_name_const = ""
export(bool) var is_global_flag = true

# this flag is also the default name for the setting, so we can use it to build 
# the config dictionaries that the api uses
var flag: Flag = null 


func _ready():
	toggle_mode = true
	var error = connect("toggled", self, "_on_config_button_toggled")
	l.error(error, l.CONNECTION_FAILED)
	if flag_name_const == "":
		if requieres_flag:
			l.g("Toggle button does not have a flag assigned at: " + get_path())
	else:
		Director.connect_global_file_loaded(self, "_on_global_file_loaded")


func _on_global_file_loaded():
	var flag_name = Consts.get(flag_name_const)
	if flag_name == null:
		l.g("Toggle button has a flag not registered in consts assigned at: " + get_path())
		return
		
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


func _on_config_button_toggled(toggled):
	if flag == null:
		return
	
	if toggled:
		flag.value = 1
	else:
		flag.value = 0
