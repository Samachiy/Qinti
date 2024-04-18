tool
extends HBoxContainer


onready var popup_menu = $PopupMenu
onready var option_button = $OptionButton
onready var normal_button = $Button
onready var label = $Label

export(String) var text = '' setget set_text
export(bool) var requieres_flag: bool = true
export(String) var flag_name_const = ""
export(bool) var is_global_flag = true

var item_ids: Dictionary = {} # {index_number: string_id, ...}
var item_ids_by_label: Dictionary = {} # {string_id: index_number, ...}
var selected_id = 0
var flag: Flag = null
var select_flag_on_global_load: bool = false

signal option_selected(label_id, index_id)

func _ready():
	if Engine.editor_hint:
		return 
	
	option_button.visible = true
	normal_button.visible = false
#	option_button.visible = false
#	normal_button.visible = true
	if text.empty():
		label.visible = false
	
	set_text(text)
	if flag_name_const == "":
		if requieres_flag:
			l.g("Smart option button does not have a flag assigned at: " + get_path())
	else:
		Director.connect_global_file_loaded(self, "_on_global_file_loaded")


func _on_global_file_loaded():
	var flag_name = Consts.get(flag_name_const)
	if flag_name == null:
		l.g("Smart option button has a flag not registered in consts assigned at: " + get_path())
		return
	
	flag = Flags.ref(flag_name)
	flag.set_up(is_global_flag, null, null, selected_id)
	if select_flag_on_global_load:
# warning-ignore:return_value_discarded
		select_flag_value()


func select_flag_value() -> bool:
	var success = false
	if flag == null:
		# if the flag name is not empty, delay until global file load
		select_flag_on_global_load = not flag_name_const.empty()
		return success
	
	if not flag.exists():
		return success
	
	if int(flag.value) in item_ids:
		# since the id is the index, the value stored in flag is both index and id
		select(int(flag.value))
		success = true
	elif item_ids.empty():
		l.g("Can't load flag into smart option button, no items to select at: " + get_path())
	
	return success


func add_tr_labeled_item(item_name: String) -> int:
	return add_labeled_item(item_name, item_name)


func add_labeled_item(item_name: String, item_label_id) -> int:
	var index_num = option_button.get_item_count()
	option_button.add_item(item_name, index_num)
	popup_menu.add_item(item_name, index_num)
	item_ids[index_num] = item_label_id
	item_ids_by_label[item_label_id] = index_num
	return index_num


func select_first(send_signal: bool = true):
	for id in item_ids.keys():
		select(id, send_signal)
		break


func select_by_label(unique_label, print_error: bool = true, send_signal: bool = true):
	var index = item_ids_by_label.get(unique_label)
	if index == null:
		if print_error:
			l.g("The label '" + unique_label + "' is not on the smart options button list at: " 
			+ get_path())
		return false
	
	select(index, send_signal)
	return true


func select(index: int, send_signal: bool = true):
	selected_id = index
	option_button.select(selected_id)
	normal_button.text = popup_menu.get_item_text(selected_id)
	option_button.hint_tooltip = normal_button.text
	normal_button.hint_tooltip = normal_button.text
	if flag != null:
		flag.value = selected_id
	
	if send_signal:
		emit_signal("option_selected", item_ids.get(selected_id), selected_id)


func get_selected():
	return item_ids.get(selected_id, null) # returns the label, not the text nor the index


func get_item_count():
	return option_button.get_item_count()


func clear():
	option_button.clear()
	popup_menu.clear()
	item_ids.clear()
	item_ids_by_label.clear()
	selected_id = 0


func _on_Button_pressed():
	popup_menu.popup_centered_clamped()


func _on_OptionButton_item_selected(index):
	select(index)


func _on_PopupMenu_index_pressed(index):
	select(index)


func set_text(value: String):
	text = value
	if Engine.editor_hint:
		$Label.text = value
	elif label != null:
		label.text = value
