extends DiffusionAPIModule

const REGPROMPT_DICT_KEY = "Regional Prompter"
const REGPROMPT_ARGS_KEY = "args"
const MASK_INDEX = 16

var reg_prompt_array = [
	true, # active
	false, # debug
	'Mask', # mode
	'Colums', # matrix mode type
	'Mask', # mask mode type
	'Prompt', # prompt mode type
	'1,1,1', # ratios
	'0', # base ratio
	false, # use base, allows to specify weight
	true, # use common
	true, # use negative common
	'Attention', # Calcmode, either Attention or Latent
	false, # Not Change AND
	'0', # LoRA Textencoder, necessary onlyif using Latent
	'0', # LoRA U-Net, necessary only if using Latent
	'0', # Threshold, intensity of the regions separated by comma
	'path/to/mask.png'
]


var color_filter: ShaderMaterial = preload("res://ui/shaders/filter_one_color_material.tres")
var colors = []
#var colors = [
#	Color().from_hsv(0, 0.5, 0.5),
#	Color().from_hsv(0.5, 0.5, 0.5),
#	Color().from_hsv(0.25, 0.5, 0.5),
#	Color().from_hsv(0.75, 0.5, 0.5),
#	Color().from_hsv(0.125, 0.5, 0.5),
#	Color().from_hsv(0.375, 0.5, 0.5),
#	Color().from_hsv(0.625, 0.5, 0.5),
#	Color().from_hsv(0.875, 0.5, 0.5),
#]
signal mask_color_checked
signal regions_baked


func bake_regions():
	if api.regions_to_bake.empty():
		yield(get_tree(), "idle_frame")
		return
	
	# regions_to_bake: Array = [] # [ [rect2_1, data_dict1], [rect2_2, data_dict2], ... ]
	var original_size = api.regions_to_bake.size()
	colors = generate_colors(original_size)
	var final_size = colors.size()
	
	# We trim regions we are not going to use
	# The first regions are the ones with lowest priority
	if original_size > final_size:
		api.regions_to_bake = api.regions_to_bake.slice(
				original_size - final_size, 
				original_size - 1 # end is inclusive
		) 
	
	# We create the color mask for regional prompting
	var image = Image.new()
	var size_x = api.request_data[Consts.I_WIDTH]
	var size_y = api.request_data[Consts.I_HEIGHT]
	image.create(size_x, size_y, false, Image.FORMAT_RGBA8)
	for i in range(api.regions_to_bake.size()):
		var rect = api.regions_to_bake[i][0] # from less priority to more
		var color = colors[-i] # colors are from more priority to less
		image.fill_rect(rect, color)
	
	# We remove the regions whose color is not present
	var valid_regions = [] # regions that are present in the current mask
	for i in range(api.regions_to_bake.size()):
		var color = colors[-i] # colors are from more priority to less
		yield(check_mask_color(image, color, valid_regions, i), "mask_color_checked")
	
	# We make the final mask
	var final_mask = Image.new()
	size_x = api.request_data[Consts.I_WIDTH]
	size_y = api.request_data[Consts.I_HEIGHT]
	final_mask.create(size_x, size_y, false, Image.FORMAT_RGBA8)
	colors.resize(valid_regions.size()) # We remove excess colors, less priority are last
	for i in range(valid_regions.size()):
		var rect = valid_regions[i][0] # from less priority to more
		var color = colors[-i] # colors are from more priority to less
		final_mask.fill_rect(rect, color)
	
	# We save the image and add it's path to the request data
	var path = PCData.globalize_path("user://regions_mask.png")
	final_mask.save_png(path)
	var reg_prompt_data = reg_prompt_array.duplicate(true)
	reg_prompt_data[MASK_INDEX] = path
	_add_regional_prompting_to_data(reg_prompt_data)
	
	# We add the prompt (the one with the BREAKs) to the request data
	var prompt = api.request_data[Consts.I_PROMPT]
	var region_data: Dictionary = {}
	for i in range(valid_regions.size() - 1, -1, -1):
		region_data = valid_regions[i][1]
		prompt += " BREAK " + region_data.get(RegionArea2D.DESCRIPTION, '')
	
	api.request_data[Consts.I_PROMPT] = prompt
	
	# We communicate that the regions have been baked
	emit_signal("regions_baked")


func check_mask_color(mask:Image, color: Color, valid_regions: Array, region_index):
	color_filter.set_shader_param("target_color", Vector3(color.r, color.g, color.b))
	ImageProcessor.process_image(
			mask, color_filter, 
			self, "_on_mask_color_checked", 
			[valid_regions, region_index]
	)
	return self


func _on_mask_color_checked(filtered_image: Image, valid_regions: Array, region_index: int):
	if not filtered_image.is_invisible():
		valid_regions.append(api.regions_to_bake[region_index])
	
	emit_signal("mask_color_checked")


func generate_colors(amount: int):
	var generated_colors = {} # { h1: Color(h, s, v)1, h2: Color(h, s, v)2, ... }
	var step_size = 0.5
	var h = 0
	while generated_colors.size() < amount:
		if not generated_colors.has(h):
			generated_colors[h] = Color().from_hsv(h, 0.5, 0.5)
		
		h += step_size
		if h >= 1.0:
			step_size = step_size / 2
			h = step_size
		
		if step_size <= 0.03:
			break
	
	return generated_colors.values()


func _add_regional_prompting_to_data(array: Array):
	var always_on_scripts_dict: Dictionary = api.request_data[Consts.I_ALWAYS_ON_SCRIPTS]
	if not always_on_scripts_dict.has(REGPROMPT_DICT_KEY):
		always_on_scripts_dict[REGPROMPT_DICT_KEY] = {REGPROMPT_ARGS_KEY: []}
	
	always_on_scripts_dict[REGPROMPT_DICT_KEY][REGPROMPT_ARGS_KEY].append(array)
