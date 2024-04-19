extends ColorPickerButton


var eyedropper: ToolButton = null
var entered_popup: bool = false


func _ready():
	var aux = get_picker().get_child(1).get_child(1)
	var e = get_popup().connect("visibility_changed", self, "_on_visibility_changed")
	l.error(e, l.CONNECTION_FAILED)
	get_popup().popup_exclusive = true
	set_process(false)
	if aux is ToolButton:
		eyedropper = aux
		var error = eyedropper.connect("pressed", self, "_on_eyedropper_pressed")
		l.error(error, l.CONNECTION_FAILED)


func _process(_delta):
	if entered_popup:
		if not get_popup().get_global_rect().has_point(get_global_mouse_position()):
			get_popup().hide()
	elif get_popup().get_global_rect().has_point(get_global_mouse_position()):
		entered_popup = true


func _on_visibility_changed():
	set_process(get_popup().visible)
	entered_popup = false


func _on_eyedropper_pressed():
	get_popup().hide()



# DEPRECATED, color picker eyedropper works just fine without this now

#	Cue.new(Consts.ROLE_COLOR_PICKER_SERVICE, "request_eyedropper").args([
#			self, "_on_color_picker_service_color_changed"]).execute()
#
#
#func _on_color_picker_service_color_changed(new_color: Color):
#	color = new_color # signal _on_color_changed is already sent with this
