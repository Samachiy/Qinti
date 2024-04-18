extends Container

const COMMON_AREA_MOUSE_EXIT_TIME = 0.4

onready var timer = $Timer

export(NodePath) var main_area_control
export(NodePath) var aux_area_control_1

var main_area_1: Node
var aux_area_1: Node
var current_area_obj: Control = null
var current_area_rect2: Rect2
var current_area_original_filter
var is_in_area: bool = false

# On android, move all the children to a normal pop up and don't connect anything

signal mouse_exited_areas

func _ready():
	#var e = connect("resized", self, "_on_resized")
	#l.error(e, l.CONNECTION_FAILED)
	main_area_1 = connect_area(main_area_control)
	aux_area_1 = connect_area(aux_area_control_1)


func _process(_delta):
	if not is_in_area:
		return
	
	if not current_area_rect2.has_point(get_global_mouse_position()):
		if current_area_obj == main_area_1:
			start_mouse_exited_process()
		elif is_in_area:
			timer.start(COMMON_AREA_MOUSE_EXIT_TIME)
		is_in_area = false


func connect_area(area_path: NodePath):
	var area_obj = get_node_or_null(area_path)
	if not area_obj is Control:
		return
	
	var e = area_obj.connect("mouse_entered", self, "_on_area_mouse_entered", [area_obj])
	l.error(e, l.CONNECTION_FAILED)
	return area_obj


func _on_resized():
	for child in get_children():
		if child is Control:
			child.rect_size = rect_size


func _on_area_mouse_entered(area_obj: Control):
	if not is_visible_in_tree():
		current_area_rect2 = area_obj.get_global_rect()
		current_area_obj = area_obj
		current_area_original_filter = current_area_obj.mouse_filter
		# We just record the area but don't do anything
		return
	
	timer.stop()
	is_in_area = true
	if current_area_obj != null:
		current_area_obj.mouse_filter = current_area_original_filter
	
	current_area_rect2 = area_obj.get_global_rect()
	current_area_obj = area_obj
	current_area_original_filter = current_area_obj.mouse_filter
	if area_obj == main_area_1:
		current_area_obj.mouse_filter = MOUSE_FILTER_IGNORE


func _on_Timer_timeout():
	start_mouse_exited_process()


func start_mouse_exited_process():
	if current_area_obj != null:
		current_area_obj.mouse_filter = current_area_original_filter
		current_area_obj = null
	
	timer.stop()
	emit_signal("mouse_exited_areas")


func _on_PopupFastSettingsPanel_visibility_changed():
	if is_visible_in_tree():
		is_in_area = true
