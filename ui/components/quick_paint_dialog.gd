extends WindowDialog

onready var denoising_strenght = $VBoxContainer/DenoisingStrenght
onready var use_modifiers = $VBoxContainer/Options/UseModifiers
onready var local_generate_button = $"%Generate"


var generation_confirmed: bool = false


func _ready():
	Roles.request_role(self, Consts.ROLE_DIALOG_QUICK_PAINT)
	var e = connect("popup_hide", self, "_on_popup_closed")
	l.error(e, l.CONNECTION_FAILED)
	local_generate_button.connect("pressed", self, "_on_generation_confirmed")


func request_dialog(_cue: Cue = null):
	var settings_cue = Cue.new(Consts.ROLE_CONTROL_IN_PAINT, "get_settings_cue").execute()
	
	denoising_strenght.set_value(settings_cue.get_option(
			Consts.I_DENOISING_STRENGTH, 
			denoising_strenght.get_value()
	))
	use_modifiers.pressed = settings_cue.get_at(
			0, use_modifiers.pressed)
	
	
	popup_centered_minsize()


func _on_generation_confirmed():
	generation_confirmed = true
	Cue.new(Consts.ROLE_CONTROL_IN_PAINT, "quick_img2img").args([
			use_modifiers.pressed
	]).opts({
			Consts.I_DENOISING_STRENGTH: denoising_strenght.get_value(),
	}).execute()


func _on_popup_closed():
	if not generation_confirmed:
		Cue.new(Consts.ROLE_CONTROL_IN_PAINT, "set_settings_cue").args([
				use_modifiers.pressed
		]).opts({
				Consts.I_DENOISING_STRENGTH: denoising_strenght.get_value(),
		}).execute()
