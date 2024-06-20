tool
extends Node

onready var test_timer = $TestTimer

export(bool) var test_accent_color = false
export(Color, RGBA) var test_main_accent_color setget set_main_accent_color
export(Color, RGBA) var test_sub_accent_color setget set_sub_accent_color

var main_theme = preload("res://themes/main_theme.tres")
var modifier_theme = preload("res://themes/modifier_theme.tres")
var sub_theme = preload("res://themes/sub_theme.tres")
var tutorial_theme = preload("res://themes/tutorial_theme.tres")
var thumbnail_theme = preload("res://themes/thumbnail_theme.tres")
var is_ready = false
var current_theme: ThemeData = null
var flag: Flag = null
var flag_name: String = "theme_enum"
var is_busy: bool = false

enum{
	# Theme enums
	BLUE_LIGHT,
	BLUE_DARK,
	ORANGE_LIGHT,
	ORANGE_DARK,
	PINK_LIGHT,
	PINK_DARK,
	RED_LIGHT,
	RED_DARK,
	# Types
	LIGHT_TYPE,
	DARK_TYPE,
}


onready var data: Dictionary = {
	BLUE_LIGHT: ThemeData.new(
			"THEME_BLUE_LIGHT_STYLE",
			_compose_dict(Consts.GENERIC_LIGHT_PRESET, Consts.THEME_BLUE_LIGHT_STYLE),
			Consts.THEME_LIGHT_TYPE,
			false,
			BLUE_DARK,
			Consts.THEME_BLUE_LIGHT_STYLE[Consts.ACCENT_COLOR_A]),
	BLUE_DARK: ThemeData.new(
			"THEME_BLUE_DARK_STYLE",
			_compose_dict(Consts.GENERIC_DARK_PRESET, Consts.THEME_BLUE_DARK_STYLE),
			Consts.THEME_DARK_TYPE,
			true,
			BLUE_LIGHT,
			Consts.THEME_BLUE_DARK_STYLE[Consts.ACCENT_COLOR_A]),
	ORANGE_LIGHT: ThemeData.new(
			"THEME_ORANGE_LIGHT_STYLE",
			_compose_dict(Consts.GENERIC_LIGHT_PRESET, Consts.THEME_ORANGE_LIGHT_STYLE),
			Consts.THEME_LIGHT_TYPE,
			false,
			ORANGE_DARK,
			Consts.THEME_ORANGE_LIGHT_STYLE[Consts.ACCENT_COLOR_AUX1_A]),
	ORANGE_DARK: ThemeData.new(
			"THEME_ORANGE_DARK_STYLE",
			_compose_dict(Consts.GENERIC_DARK_PRESET, Consts.THEME_ORANGE_DARK_STYLE),
			Consts.THEME_DARK_TYPE,
			true,
			ORANGE_LIGHT,
			Consts.THEME_ORANGE_DARK_STYLE[Consts.ACCENT_COLOR_AUX1_A]),
	PINK_LIGHT: ThemeData.new(
			"THEME_PINK_LIGHT_STYLE",
			_compose_dict(Consts.GENERIC_LIGHT_PRESET, Consts.THEME_PINK_LIGHT_STYLE),
			Consts.THEME_LIGHT_TYPE,
			false,
			PINK_DARK,
			Consts.THEME_PINK_LIGHT_STYLE[Consts.ACCENT_COLOR_A]),
	PINK_DARK: ThemeData.new(
			"THEME_PINK_DARK_STYLE",
			_compose_dict(Consts.GENERIC_DARK_PRESET, Consts.THEME_PINK_DARK_STYLE),
			Consts.THEME_DARK_TYPE,
			true,
			PINK_LIGHT,
			Consts.THEME_PINK_DARK_STYLE[Consts.ACCENT_COLOR_A]),
	RED_LIGHT: ThemeData.new(
			"THEME_RED_LIGHT_STYLE",
			_compose_dict(Consts.GENERIC_LIGHT_PRESET, Consts.THEME_RED_LIGHT_STYLE),
			Consts.THEME_LIGHT_TYPE,
			false,
			RED_DARK,
			Consts.THEME_RED_LIGHT_STYLE[Consts.ACCENT_COLOR_A]),
	RED_DARK: ThemeData.new(
			"THEME_RED_DARK_STYLE",
			_compose_dict(Consts.GENERIC_DARK_PRESET, Consts.THEME_RED_DARK_STYLE),
			Consts.THEME_DARK_TYPE,
			true,
			RED_LIGHT,
			Consts.THEME_RED_DARK_STYLE[Consts.ACCENT_COLOR_AUX1_A]),
}

signal theme_changed


func _ready():
	if not Engine.editor_hint:
		OS.min_window_size = Vector2(800, 715)
		#change_theme(BLUE_LIGHT, 0.7)
		load_theme(BLUE_DARK, 0)
		is_ready = true
		var theme: ThemeData
		for theme_enum in data.keys():
			theme = data[theme_enum]
			theme.theme_enum = theme_enum
		Director.connect_global_file_loaded(self, "_on_global_file_loaded")


func _on_global_file_loaded():
	flag = Flags.ref(flag_name)
	flag.set_up(true, null, null, BLUE_DARK)
	load_theme(flag.get_value(), 0)


func get_theme_accent(theme_enum: int):
	match theme_enum:
		BLUE_LIGHT:
			return Consts.THEME_BLUE_LIGHT_STYLE[Consts.ACCENT_COLOR_A]
		BLUE_DARK:
			return Consts.THEME_BLUE_DARK_STYLE[Consts.ACCENT_COLOR_A]


func load_theme(theme_enum: int, time: float = 0, tween = null, force_type: int = -1):
	var theme_data = data.get(theme_enum, null)
	if not theme_data is ThemeData:
		l.g("Theme data wasn't found. Theme enum: " + str(theme_enum))
		return
	
	match force_type:
		LIGHT_TYPE:
			if theme_data.is_dark:
				theme_data = data.get(theme_data.opposite_theme, null)
		DARK_TYPE:
			if not theme_data.is_dark:
				theme_data = data.get(theme_data.opposite_theme, null)
	
	if not theme_data is ThemeData:
		l.g("Forced type theme data wasn't found. Theme enum: " + str(theme_enum))
		return
	
	load_theme_data(theme_data, time, tween)
	if flag is Flag:
		flag.value = theme_enum


func load_theme_data(theme_data: ThemeData, time: float = 0, tween = null):
	if theme_data == null:
		return
	
	is_busy = true
	current_theme = theme_data
	current_theme.load_style_in_group(Consts.THEME_MODULATE_GROUP_STYLE, time)
	current_theme.load_type_in_group(Consts.THEME_MODULATE_GROUP_TYPE, time)
	current_theme.load_in_theme_resource(main_theme, time, tween)
	current_theme.load_in_theme_resource(modifier_theme, time, tween)
	current_theme.load_in_theme_resource(sub_theme, time, tween)
	current_theme.load_in_theme_resource(tutorial_theme, time, tween)
	current_theme.load_in_theme_resource(thumbnail_theme, time, tween)
	emit_signal("theme_changed")
	is_busy = false
	
	if flag is Flag:
		flag.value = theme_data.theme_enum


func toggle_light_dark_theme():
	if current_theme == null:
		l.g("There's no theme selected, can't toggle dark/light change")
		return
	
	load_theme(current_theme.opposite_theme)


func set_light_dark_theme(type: int):
	if current_theme == null:
		l.g("There's no theme selected, can't set dark/light change")
		return
	
	match type:
		LIGHT_TYPE:
			if current_theme.is_dark:
				toggle_light_dark_theme()
		DARK_TYPE:
			if not current_theme.is_dark:
				toggle_light_dark_theme()


func set_main_accent_color(value):
	if test_timer == null:
		return
	
	test_main_accent_color = value
	test_timer.start()


func set_sub_accent_color(value):
	if test_timer == null:
		return
	
	test_sub_accent_color = value
	test_timer.start()


func _test_accent_color(main_accent, sub_accent):
	if Engine.editor_hint:
		return
	
	if not is_ready or current_theme == null:
		return
	
	var style_color_dict
	var type_color_dict
	if current_theme.is_dark:
		style_color_dict = Consts.THEME_BLUE_DARK_STYLE
		type_color_dict = Consts.THEME_DARK_TYPE
	else:
		style_color_dict = Consts.THEME_BLUE_LIGHT_STYLE
		type_color_dict = Consts.THEME_LIGHT_TYPE
	
	var glass_accent = sub_accent
	var low_glass_accent = sub_accent
	main_accent.a8 = Consts.ACCENT_COLOR_A
	sub_accent.a8 = Consts.ACCENT_COLOR_AUX1_A
	glass_accent.a8 = Consts.ACCENT_GLASS_HOVER_A
	low_glass_accent.a8 = Consts.ACCENT_GLASS_LOW_A
	style_color_dict[Consts.ACCENT_COLOR_A] = main_accent
	style_color_dict[Consts.ACCENT_COLOR_AUX1_A] = sub_accent
	style_color_dict[Consts.ACCENT_GLASS_HOVER_A] = glass_accent
	style_color_dict[Consts.ACCENT_GLASS_LOW_A] = low_glass_accent
	UIOrganizer.change_group_modulate_by_alpha(Consts.THEME_MODULATE_GROUP_STYLE, style_color_dict)
	UIOrganizer.change_theme_colors_by_alpha(
			main_theme, style_color_dict, type_color_dict, 0)
	UIOrganizer.change_theme_colors_by_alpha(
			modifier_theme, style_color_dict, type_color_dict, 0)
	UIOrganizer.change_theme_colors_by_alpha(
			sub_theme, style_color_dict, type_color_dict, 0)
	UIOrganizer.change_theme_colors_by_alpha(
			tutorial_theme, style_color_dict, type_color_dict, 0)
	UIOrganizer.change_theme_colors_by_alpha(
			thumbnail_theme, style_color_dict, type_color_dict, 0)
	


func get_accent_color() -> Color:
	if current_theme is ThemeData:
		return current_theme.get_accent_color()
	else:
		l.g('No theme loaded to retrieve accent color')
		return Color.white


func get_aux_accent_color() -> Color:
	if current_theme is ThemeData:
		return current_theme.get_aux_accent_color()
	else:
		l.g('No theme loaded to retrieve aux accent color')
		return Color.white


func get_main_color() -> Color:
	if current_theme is ThemeData:
		return current_theme.get_main_color()
	else:
		l.g('No theme loaded to retrieve aux accent color')
		return Color.white


func _on_TestTimer_timeout():
	test_timer.stop()
	_test_accent_color(test_main_accent_color, test_sub_accent_color)


func _compose_dict(dict_a: Dictionary, dict_b: Dictionary):
	var resul = dict_a.duplicate()
	resul.merge(dict_b)
	return resul
