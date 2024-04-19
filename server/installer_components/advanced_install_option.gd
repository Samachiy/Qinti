extends HBoxContainer


export(NodePath) var selector
var selector_node

func _ready():
	selector_node = get_node_or_null(selector)
	if selector_node is CheckBox:
		selector_node.connect("toggled", self, "_on_AdvancedInstallOptions_toggled")
		_on_AdvancedInstallOptions_toggled(selector_node.pressed)
	else:
		l.g("Advanced install option '" + name + "' doesn't have a checkbox specified")


func _on_AdvancedInstallOptions_toggled(button_pressed):
	for child in get_children():
		child.visible = button_pressed
