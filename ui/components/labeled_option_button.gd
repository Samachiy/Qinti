extends OptionButton

class_name LabeledOptionButton

var item_ids: Dictionary = {} # {string_id: index_number, ...}


func add_labeled_item(item_name: String, item_label):
	var index_num = get_item_count()
	add_item(item_name, index_num)
	item_ids[item_label] = index_num
