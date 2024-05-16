extends Resource

class_name ModifierType

export(Dictionary) var types = {} # {node_name: translation_key, ...}
export(String, MULTILINE) var order = '' # 1 node_name1 \n 2 node_name2 \n ...

# The type key/name should be the same name as the node in Modifier.tscn

var order_dict = {} # { 1: node_name1, 2: node_name2, ... }
var controlnet_feature = {} # {node_name: translation_key, ...}
var image_info_feature = {} # {node_name: translation_key, ...}
var img_to_image_feature = {} # {node_name: translation_key, ...}


func fill_combobox(smart_option_button: Control, default_select_label: String):
	sort_types_and_features()
	smart_option_button.clear()
	_refresh_combobox(smart_option_button)
	for type in types.keys():
		if is_supported_mode(type):
			smart_option_button.add_labeled_item(types[type], type)
	
	if not default_select_label.empty():
		smart_option_button.select_by_label(default_select_label)


func refill_combobox(smart_option_button: Control, current_label: String, current_text: String) -> int:
	_refresh_combobox(smart_option_button)
	var success = smart_option_button.select_by_label(current_label, false, false)
	if success:
		return 1 # The current option exists
	elif current_label in types:
		smart_option_button.add_labeled_item(current_text, current_label)
		smart_option_button.select_by_label(current_label, true, false)
		return 0 # The current option doesn't exist because due to lack of feature
	else:
		return -1 # The current option just doesn't exist


func _refresh_combobox(smart_option_button: Control):
	smart_option_button.clear()
	for type in types.keys():
		if is_supported_mode(type):
			smart_option_button.add_labeled_item(types[type], type)


func is_mode_tagged_as(mode_name: String, tag: String) -> bool:
	match tag:
		DiffusionServer.FEATURE_CONTROLNET:
			return mode_name in controlnet_feature
		DiffusionServer.FEATURE_IMAGE_INFO:
			return mode_name in image_info_feature
		DiffusionServer.FEATURE_IMG_TO_IMG:
			return mode_name in img_to_image_feature
		_:
			return false


func is_supported_mode(node_name):
	if node_name in controlnet_feature:
		return DiffusionServer.features.has_feature(DiffusionServer.FEATURE_CONTROLNET)
	elif node_name in image_info_feature:
		return DiffusionServer.features.has_feature(DiffusionServer.FEATURE_IMAGE_INFO)
	elif node_name in img_to_image_feature:
		return DiffusionServer.features.has_feature(DiffusionServer.FEATURE_IMG_TO_IMG)
	else:
		return true


func parser_order():
	var order_array = order.split('\n', false)
	var aux: Array
	# Parse the order
	for entry in order_array:
		aux = entry.split(' ', false)
		if aux.size() > 2:
			order_dict[aux[0]] = aux[1]
			clasify_feature(aux)
		elif aux.size() == 2:
			order_dict[aux[0]] = aux[1]
		else:
			l.g("Can't sort modifier type entry '" + str(entry) + "' at: " + resource_path)


func clasify_feature(array: Array):
	array.pop_front() # remove the order number
	var node_name = array.pop_front() # remove the node name
	var tr_key = types.get(node_name, '')
	if tr_key.empty():
		l.g("Can't add feature tag for mode '" + str(node_name) + 
				"', it is not present in types array")
		return
	
	for feature_name in array:
		match feature_name:
			DiffusionServer.FEATURE_CONTROLNET:
				controlnet_feature[node_name] = tr_key
			DiffusionServer.FEATURE_IMAGE_INFO:
				image_info_feature[node_name] = tr_key
			DiffusionServer.FEATURE_IMG_TO_IMG:
				img_to_image_feature[node_name] = tr_key
			_:
				l.g("Feature name '" + str(feature_name) + 
					"' is not a registere feature. Can't add on type: " + node_name)


func sort_types_and_features():
	if order_dict.empty():
		parser_order()
	
	var types_copy = types.duplicate(true)
	var type_name
	var type_tr_value
	var sorted: Dictionary = {}
	for num in order_dict.keys():
		type_name = order_dict[num]
		type_tr_value = types_copy.get(type_name, null)
		if type_tr_value == null:
			l.g("Can't sort modifier type '" + str(type_name) + "', type not present, at: " 
					+ resource_path)
		else:
			types_copy.erase(type_name)
			sorted[type_name] = type_tr_value
	
	# We add types that weren't specified in the order, last
	for type in types_copy.keys():
		sorted[type] = types_copy[type]
	
	types = sorted
