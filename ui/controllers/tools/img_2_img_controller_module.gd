extends Node



func is_main_board(canvas: Canvas2D):
	if canvas.board_owner is Control:
		var result = canvas.board_owner.get("is_main_board")
		if result is bool:
			return result
		else:
			return false
	else:
		return false


func quick_image_to_image(apply_modifiers: bool, canvas: Canvas2D, denoising_strenght):
	if not canvas.generation_area is GenerationArea2D:
		return
	
	var active_image = canvas.generation_area.get_contained_image()
	if active_image == null:
		l.g("Couldn't create control net config in " + name + ". Missing ImageData in cue.")
		return
	
	Cue.new(Consts.ROLE_API, "clear").execute()
	
	Cue.new(Consts.ROLE_PROMPTING_AREA, "add_prompt_and_seed_to_api").execute()
	Cue.new(Consts.ROLE_CANVAS, "apply_parameters_to_api").execute()
	if apply_modifiers:
		Cue.new(Consts.ROLE_GENERATION_INTERFACE, "apply_modifiers_to_api").execute()
	
	Cue.new(Consts.ROLE_API, "convert_to_img2img").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_controlnets").execute()
	var config = {
		Consts.I2I_INIT_IMAGES: [ImageProcessor.image_to_base64(active_image)],
		Consts.I_DENOISING_STRENGTH: denoising_strenght,
	}
	Cue.new(Consts.ROLE_API, "cue_apply_parameters").opts(config).execute()
#	Cue.new(Consts.ROLE_API, "bake_pending_regional_prompts").execute()
	var prompting_area = Roles.get_node_by_role(Consts.ROLE_PROMPTING_AREA)
	if prompting_area is Object:
		DiffusionServer.generate(prompting_area, "_on_image_generated")
	else:
		l.g("Can't quick img2img, there's no node with the role ROLE_PROMPTING_AREA")
