extends Reference

class_name ThemeData

var tr_name: String
var style_colors: Dictionary
var type_colors: Dictionary
var is_dark: bool
var opposite_theme: int
var theme_enum: int = 0
var preview_color


func _init(tr_name_: String, style_colors_: Dictionary, type_colors_: Dictionary, 
is_dark_: bool, opposite_theme_: int, preview_color_: Color):
	tr_name = tr_name_
	style_colors = style_colors_
	type_colors = type_colors_
	type_colors.merge(style_colors)
	is_dark = is_dark_
	opposite_theme = opposite_theme_
	preview_color = preview_color_


func get_accent_color():
	return style_colors.get(Consts.ACCENT_COLOR_A)


func get_aux_accent_color():
	return style_colors.get(Consts.ACCENT_COLOR_AUX1_A)


func get_main_color():
	return style_colors.get(Consts.MAIN_COLOR_A)


func load_style_in_group(group_name: String, time: float):
	UIOrganizer.change_group_modulate_by_alpha(group_name, style_colors, time)


func load_type_in_group(group_name: String, time: float):
	UIOrganizer.change_group_modulate_by_alpha(group_name, type_colors, time)


func load_in_theme_resource(theme_resource: Theme, time: float, tween):
	UIOrganizer.change_theme_colors_by_alpha(
			theme_resource, style_colors, type_colors, time, tween)
