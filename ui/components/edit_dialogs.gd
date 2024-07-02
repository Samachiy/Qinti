extends Control



func _on_EditDialogs_resized():
	for child in get_children():
		if child is Popup:
			child.rect_size = rect_size * 0.5
			child.rect_position = rect_size / 2 - child.rect_size / 2


func get_popup_proportion(popup: Popup) -> Vector2:
	if popup.has_method("get_popup_proportion"):
		return popup.get_popup_proportion()
	else:
		return Vector2(0.5, 0.5)
	
