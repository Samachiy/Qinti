extends Control



func _on_EditDialogs_resized():
	for child in get_children():
		if child is Popup:
			child.rect_size = rect_size * 0.5
			child.rect_position = rect_size / 2 - child.rect_size / 2
