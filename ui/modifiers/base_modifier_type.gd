extends Resource

class_name ModifierType

export(Dictionary) var types = {} # {node_name: translation_key, ...}
export(String, MULTILINE) var order = '' # 1 node_name1 \n 2 node_name2 \n ...

# The type key/name should be the same name as the node in Modifier.tscn

var order_dict = {}


func fill_combobox(smart_option_button: Control, default_select_label: String):
	sort_types()
	smart_option_button.clear()
	for type in types.keys():
		smart_option_button.add_labeled_item(types[type], type)
	
	if not default_select_label.empty():
		smart_option_button.select_by_label(default_select_label)


func parser_order():
	var order_array = order.split('\n', false)
	var aux: Array
	# Parse the order
	for entry in order_array:
		aux = entry.split(' ', false)
		if aux.size() == 2:
			order_dict[aux[0]] = aux[1]
		else:
			l.g("Can't sort modifier type entry '" + str(entry) + "' at: " + resource_path)


func sort_types():
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
