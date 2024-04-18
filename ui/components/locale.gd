extends Node

# The transalation key should be the available_string.to_upper()

var available = [
	"en", "es"
]


func _ready():
	Roles.request_role(self, Consts.ROLE_LOCALE)
	Roles.request_role_on_roles_cleared(self, Consts.ROLE_LOCALE)
	Director.connect_global_save_cues_requested(self, "_on_global_save_cues_requested")


func cue_locale(cue: Cue):
	# [ locale_code: String ]
	var locale_code = cue.str_at(0, 'en')
	UIOrganizer.set_locale(locale_code)


func _on_global_save_cues_requested():
	Director.add_global_save_cue(
			Consts.ROLE_LOCALE, 
			"cue_locale", 
			[TranslationServer.get_locale()]
		)
