extends Controller

class_name ControlnetNoCanvasController

const SCROLL_SCALE_AMOUNT = 20
const DISABLE_PREPROCESSOR_KEYWORD = "None"

onready var cn_config = $Container/Configs/ControlNetConfigs
onready var scroll = $Container
onready var top_gradient = $TopGradient
onready var bottom_gradient = $BottomGradient

var layer_name = ''
#var layer2d: Layer2D = null
var selected_preprocessor: String = ''
var original_image_data = null
var preprocessor_material = null
var texture_material = null
var overlay_underlay_material = null
var cn_model_type: String = ''
var image_data: ImageData = null


func set_image(cue: Cue):
	image_data = cue.get_at(0, null)
	if image_data == null:
		l.g("Couldn't set image in Image info controller")
		return
	
	canvas.set_image_data(image_data)


func get_cn_config(cue: Cue) -> Cue:
	# [ active_image: Image, default: bool = true ]
	var active_image = cue.get_at(0, null)
	var default = cue.bool_at(1, true, false)
	if active_image == null:
		l.g("Couldn't create control net config in " + name + ". Missing ImageData in cue.")
		return null
	
	return cn_config.get_controlnet_config(active_image, default)


func clear(_cue: Cue = null):
	pass


func _on_scroll_changed():
	var scrollbar = scroll.get_v_scrollbar()
	UIOrganizer.show_v_scroll_indicator(scrollbar, top_gradient, bottom_gradient, 8)
