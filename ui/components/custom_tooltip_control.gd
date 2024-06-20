extends Control


var tooltip = preload("res://ui/components/custom_tooltip.tscn")

func _make_custom_tooltip(for_text: String):
	var tooltip_node = tooltip.instance()
	tooltip_node.text = for_text
	tooltip_node.rect_min_size.x = 200
	return tooltip_node
