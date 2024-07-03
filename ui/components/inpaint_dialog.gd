extends WindowDialog

onready var denoising_strenght = $HBoxContainer/DenoisingStrenght
onready var mask_blur = $HBoxContainer/MaskBlur
onready var use_modifiers = $HBoxContainer/GridContainer/UseModifiers
onready var invert_mask = $HBoxContainer/GridContainer/InvertMask
onready var inpaint_full_res = $HBoxContainer/GridContainer/InpaintFullRes
onready var local_generate_button = $"%Generate"


var generation_confirmed: bool = false


func _ready():
	Roles.request_role(self, Consts.ROLE_DIALOG_IN_PAINT)
	var e = connect("popup_hide", self, "_on_popup_closed")
	l.error(e, l.CONNECTION_FAILED)
	local_generate_button.connect("pressed", self, "_on_generation_confirmed")


func request_dialog(_cue: Cue = null):
	var settings_cue = Cue.new(Consts.ROLE_CONTROL_IN_PAINT, "get_settings_cue").execute()
	
	denoising_strenght.set_value(settings_cue.get_option(
			Consts.I_DENOISING_STRENGTH, 
			denoising_strenght.get_value()
	))
	mask_blur.set_value(settings_cue.get_option(
			Consts.I2I_MASK_BLUR, 
			mask_blur.get_value()
	))
	inpaint_full_res.pressed = settings_cue.get_option(
			Consts.I2I_INPAINT_FULL_RES, inpaint_full_res.pressed)
	invert_mask.pressed = settings_cue.get_option(
			Consts.I2I_INPAINTING_MASK_INVERT, invert_mask.pressed)
	use_modifiers.pressed = settings_cue.get_at(
			0, use_modifiers.pressed)
	
	
	popup_centered_minsize()


func _on_generation_confirmed():
	generation_confirmed = true
	Cue.new(Consts.ROLE_CONTROL_IN_PAINT, "inpaint").args([
			use_modifiers.pressed
	]).opts({
			Consts.I_DENOISING_STRENGTH: denoising_strenght.get_value(),
			Consts.I2I_MASK_BLUR: mask_blur.get_value(),
			Consts.I2I_INPAINT_FULL_RES: inpaint_full_res.pressed,
			Consts.I2I_INPAINTING_MASK_INVERT: invert_mask.pressed,
	}).execute()


func _on_popup_closed():
	if not generation_confirmed:
		Cue.new(Consts.ROLE_CONTROL_IN_PAINT, "set_settings_cue").args([
				use_modifiers.pressed
		]).opts({
				Consts.I_DENOISING_STRENGTH: denoising_strenght.get_value(),
				Consts.I2I_MASK_BLUR: mask_blur.get_value(),
				Consts.I2I_INPAINT_FULL_RES: inpaint_full_res.pressed,
				Consts.I2I_INPAINTING_MASK_INVERT: invert_mask.pressed,
		}).execute()


func get_popup_proportion():
	return Vector2(0.3, 0.2)
