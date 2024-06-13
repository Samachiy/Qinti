tool
extends HBoxContainer

onready var label = $Label
onready var slider = $Slider
onready var amount = $Amount/Amount
onready var more_button = $Amount/More
onready var less_button = $Amount/Less

export(String) var text = "" setget set_label
export(float) var min_value = 0.0 setget set_min_value
export(float) var max_value = 100.0 setget set_max_value
export(float) var step = 1.0 setget set_step
export(float) var default_value = 1.0 setget set_default_value
export(bool) var allow_decimals = false
export(bool) var no_upward_limit = false
export(bool) var requieres_flag: bool = true
export(String) var flag_name_const = ""
export(NodePath) var flag_prefix_node_name: NodePath
export(bool) var is_global_flag = true

# this flag is also the default name for the setting, so we can use it to build 
# the config dictionaries that the api uses
var flag: Flag = null 

var slider_value: float setget set_value, get_value
var last_amount_label_value: String = ''
var last_value = default_value
var is_editing_amount_text: bool = false
var flag_name


signal value_changed(value)
signal flag_loaded(flag_ref)

func _ready():
	if not Engine.editor_hint:
		more_button.modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
		less_button.modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
		UIOrganizer.add_to_theme_by_modulate_group(
				more_button, 
				Consts.THEME_MODULATE_GROUP_STYLE)
		UIOrganizer.add_to_theme_by_modulate_group(
				less_button, 
				Consts.THEME_MODULATE_GROUP_STYLE)
		
		if flag_name_const == "":
			if requieres_flag:
				l.g("Slider does not have a flag assigned at: " + get_path())
		else:
			add_to_group(Consts.UI_UPDATE_FLAG_ON_LOAD_GROUP)
			Director.connect_global_file_loaded(self, "_on_global_file_loaded")
	
	set_label(text)
	set_min_value(min_value)
	set_max_value(max_value)
	set_step(step)
	set_amount_label(str(default_value), true)


func _on_global_file_loaded():
	update_with_flag()


func update_with_flag(_cue: Cue = null):
	if flag == null or not flag.exists():
		flag_name = Consts.get(flag_name_const)
		if flag_name == null:
			l.g("Slider has a flag not registered in consts assigned at: " + get_path())
			return
		
		if not flag_prefix_node_name.is_empty():
			var prefix_node = get_node_or_null(flag_prefix_node_name)
			if prefix_node != null:
				flag_name = prefix_node.name + "_" + flag_name
		
		flag = Flags.ref(flag_name)
		flag.set_up(is_global_flag, null, null, get_value())
	
	set_value(flag.get_value())
	emit_signal("flag_loaded", flag)


func set_label(value):
	text = value
	if Engine.editor_hint:
		$Label.text = text
	elif label != null:
		label.text = text


func set_min_value(value):
	min_value = value
	if Engine.editor_hint:
		$Slider.min_value = min_value
	elif slider != null:
		slider.min_value = min_value


func set_max_value(value):
	max_value = value
	if Engine.editor_hint:
		$Slider.max_value = max_value
	elif slider != null:
		slider.max_value = max_value


func set_step(value):
	step = value
	if Engine.editor_hint:
		$Slider.step = step
	elif slider != null:
		slider.step = step


func set_default_value(value):
	default_value = value
	if Engine.editor_hint:
		$Slider.value = default_value
	elif slider != null:
		slider.value = default_value


func get_value():
	if Engine.editor_hint:
		return $Slider.value
	elif slider != null:
		return last_value


func set_value(value, send_signal: bool = true):
	if Engine.editor_hint:
		$Slider.value = value
	elif slider != null:
		set_amount_label(str(value), send_signal)


func add_config_to_dict(dictionary: Dictionary):
	if flag != null:
		dictionary[flag.name] = get_value()


func _on_Slider_value_changed(value):
	slider_value = value
	if slider.has_focus():
		set_amount_label(str(value), true)
		


func _on_Amount_focus_exited():
	is_editing_amount_text = false
	set_amount_label(amount.text, true)


func _on_Amount_focus_entered():
	is_editing_amount_text = true


func _on_Amount_text_changed(_new_text):
	set_amount_label(amount.text, true)


func set_amount_label(value: String, send_signal: bool):
	if value == last_amount_label_value:
		return last_amount_label_value
	
	var parsed_text
	var aux
	if allow_decimals:
		aux = float(value)
		aux = trim_value(aux)
		slider.value = aux
		parsed_text = str(aux)
	else:
		aux = int(value)
		aux = trim_value(aux)
		slider.value = aux
		parsed_text = str(aux)
	
	if parsed_text == last_amount_label_value:
		return last_amount_label_value
	
	last_amount_label_value = parsed_text
	if not is_editing_amount_text:
		amount.text = parsed_text
	
	last_value = aux
	if flag != null:
		flag.value = aux
	if send_signal and not Engine.editor_hint:
		emit_signal("value_changed", aux)


func resend_value_changed_signal():
	emit_signal("value_changed", last_value)


func trim_value(value):
	if no_upward_limit:
		return max(value, min_value)
	else:
		return clamp(value, min_value, max_value)
	


func get_amount_label():
	if allow_decimals:
		return float(amount.text)
	else:
		return int(amount.text)


func _on_More_pressed():
	set_amount_label(str(get_amount_label() + step), true)


func _on_Less_pressed():
	set_amount_label(str(get_amount_label() - step), true)
