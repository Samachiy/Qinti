extends Control


func _ready():
	modulate.a8 = Consts.LABEL_FONT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(self, Consts.THEME_MODULATE_GROUP_TYPE)
