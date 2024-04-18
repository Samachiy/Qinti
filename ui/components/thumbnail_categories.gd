extends Resource

class_name ThumbnailCategories

export(Dictionary) var types = {} # {node_name: translation_key, ...}

# The type key/name should be the same name as the node in Toolbox.tscn


func fill_combobox(smart_option_button: Control, default_select_label: String):
	smart_option_button.clear()
	for type in types.keys():
		smart_option_button.add_labeled_item(types[type], type)
	
	if default_select_label.empty():
		smart_option_button.select_first()
	else:
		smart_option_button.select_by_label(default_select_label)

