extends FileClusterThumbnail

class_name StylingThumbnail

onready var highlight = $Highlight

var styling_data: StylingData = null


func _ready():
	highlight.visible = false


func set_styling_data(format: String):
	styling_data = StylingData.new(file_cluster, format)
	return true


func create_style_modifier():
	_disconnect_modifier_if_needed("create_style_modifier")
	create_empty_modifier()
	if modifier != null:
		modifier.set_as_style_type(styling_data)
		var file_cluster = styling_data.file_cluster
		var e = file_cluster.connect("image_data_refreshed", modifier, "_refresh_image_data_with")
		l.error(e, l.CONNECTION_FAILED)


func get_drag_data(position):
	create_style_modifier()
	return .get_drag_data(position)

func is_match(text: String):
	if styling_data == null:
		return text.empty() # If there's nothing to match, will return true
		
	if text.empty():
		return true
	
	return styling_data.file_cluster.match_string(text)


func _on_pressed():
	Cue.new(Consts.ROLE_STYLE_EDITOR, "open").args([styling_data]).execute()


func _fill_menu():
	menu.add_tr_labeled_item(Consts.MENU_EDIT)


func _on_Menu_option_pressed(label_id, _index_id):
	match label_id:
		Consts.MENU_EDIT:
			Cue.new(Consts.ROLE_STYLE_EDITOR, "open").args([styling_data]).execute()


func _on_StylingThumbnail_mouse_entered():
	highlight.modulate = ThemeChanger.get_accent_color()
	highlight.visible = true


func _on_StylingThumbnail_mouse_exited():
	highlight.visible = false
