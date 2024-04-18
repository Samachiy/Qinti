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

