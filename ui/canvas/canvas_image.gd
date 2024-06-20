extends TextureRect

onready var menu = $"%Menu"

var board_owner: Node = null
var image_data: ImageData

func _ready():
	var controller
	if board_owner is Node:
		controller = board_owner.get("controller_node")
		if controller is Node:
			controller.size_flags_vertical = Control.SIZE_EXPAND_FILL
			controller.size_flags_stretch_ratio = 2


func set_image_data(new_image_data: ImageData):
	image_data = new_image_data
	texture = image_data.texture


func get_canvas_image(_limits = null):
	return image_data.image


# warning-ignore:unused_signal
signal left_click(event)
# warning-ignore:unused_signal
signal left_click_drag(event)
# warning-ignore:unused_signal
signal right_click(event)
# warning-ignore:unused_signal
signal right_click_drag(event)
# warning-ignore:unused_signal
signal middle_click(event)
# warning-ignore:unused_signal
signal middle_click_drag(event)
# warning-ignore:unused_signal
signal scroll_up(event)
# warning-ignore:unused_signal
signal scroll_down(event)
# warning-ignore:unused_signal
signal mouse_button_released(event)
# warning-ignore:unused_signal
signal mouse_moved(event, is_inside)
# warning-ignore:unused_signal
signal mouse_exited_canvas()



func get_drag_data(_position: Vector2):
	var mydata = image_data
	var preview = TextureRect.new()
	preview.expand = true
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview.texture = image_data.texture
	preview.rect_size = rect_size
	set_drag_preview(preview)
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "set_on_top").args([preview]).execute()
	Cue.new(Consts.UI_DROP_GROUP, "enable_drop").execute()
	return mydata

