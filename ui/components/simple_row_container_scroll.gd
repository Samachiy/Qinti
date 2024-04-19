extends ScrollContainer

onready var container = $Row

enum ALING{
	LEFT,
	CENTER,
	RIGHT,
}
export var spacing: int = 10
export(ALING) var alignment: int = 0

func _ready():
	container.spacing = spacing
	container.alignment = alignment

func refresh():
	yield(get_tree(), "idle_frame")
	container.place_children()


func add_child_in_row(node: Control):
	container.add_child(node)


func remove_children():
	for child in container.get_children():
		child.queue_free()
	
