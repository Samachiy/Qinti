extends TextureButton


func _ready():
	modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
	UIOrganizer.add_to_theme_by_modulate_group(self, Consts.THEME_MODULATE_GROUP_STYLE)
