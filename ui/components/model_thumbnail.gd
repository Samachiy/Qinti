extends FileClusterThumbnail

class_name ModelThumbnail

onready var selected_frame = $SelectedFrame
onready var hover_indicator = $HoverIndicator

signal model_selected(model_thumbnail)

var is_selected: bool = false setget set_selected

func _ready():
	selected_frame.visible = false
	hover_indicator.visible = false


func set_selected(value: bool):
	is_selected = value
	if is_selected:
		selected_frame.modulate = ThemeChanger.get_accent_color()
		selected_frame.visible = true
	else:
		selected_frame.visible = false



func _on_pressed():
	emit_signal("model_selected", self)


func _fill_menu():
	menu.add_tr_labeled_item(Consts.MENU_EDIT)


func _on_Menu_option_pressed(label_id, _index_id):
	match label_id:
		Consts.MENU_EDIT:
			Cue.new(Consts.ROLE_MODEL_EDITOR, "open").args([self]).execute()
			Cue.new(Consts.ROLE_MODEL_SELECTOR, "quick_close").args([self]).execute()


func _on_FileClusterThumbnail_mouse_entered():
	hover_indicator.modulate = ThemeChanger.get_aux_accent_color()
	hover_indicator.visible = true


func _on_FileClusterThumbnail_mouse_exited():
	hover_indicator.visible = false
