extends Node

var config_slider: HBoxContainer = null
var config_checkbox: CheckBox = null

var is_set_up: bool = false

func _ready():
	var aux = get_parent()
	if aux is HBoxContainer and aux.has_method("update_with_flag"):
		config_slider = aux
	else:
		l.g("Failure to set up config slider on LayModuleBoardSlider at: " + get_path())
		return
	
	aux = config_slider.get_node_or_null("Enable")
	if aux is CheckBox and aux.has_method("update_with_flag"):
		config_checkbox = aux
	else:
		l.g("Failure to set up config checkbox on LayModuleBoardSlider at: " + get_path())
		return
	
	var e = config_slider.connect("flag_loaded", self, "_on_slider_flag_loaded")
	l.error(e, l.CONNECTION_FAILED)
#	e = config_slider.connect("flag_loaded", self, "_on_slider_value_changed")
#	l.error(e, l.CONNECTION_FAILED)
	e = config_checkbox.connect("flag_loaded", self, "_on_checkbox_flag_loaded")
	l.error(e, l.CONNECTION_FAILED)
	e = config_checkbox.connect("toggled", self, "_on_checkbox_toggled")
	l.error(e, l.CONNECTION_FAILED)
	
	
	is_set_up = true
	config_slider.resend_value_changed_signal()


func is_enabled():
	if not is_set_up:
		return false
	else:
		return config_checkbox.pressed


func _on_checkbox_toggled(_value):
	config_slider.resend_value_changed_signal()


func _on_slider_flag_loaded(_flag_ref: Flag):
	config_slider.resend_value_changed_signal()


func _on_checkbox_flag_loaded(_flag_ref: Flag):
	config_slider.resend_value_changed_signal()
