extends DiffusionAPIModule

#bake pending img2img
#    if no img2img to bake:
#        bake mask(null, has_empty_space):
#            if theres mask to bake:
#                convert to img2img
#                place mask on request data
#            else:
#                return
#    else:
#        convert to img2img
#        merge_keys and bake mask(mask)
#
#
#Calculate empty space using image.is_invisible()

const IMG2IMG_SERVICE = "img2img"

# Removed keys: 
# styles, subseed, subseed_strength, seed_resize_from_h, seed_resize_from_w, 
# do_not_save_samples, do_not_save_grid, sampler_index, alwayson_scripts, script_name, 
# script_args, include_init_images, initial_noise_multiplier, inpaint_full_res_padding
# inpainting_fill
# (removing these gives me consistent results with web ui)
# eta: 0, s_churn: 0, s_tmax: 0, s_tmin: 0, s_noise: 1 
# (According to the source code, this is not that effective so it will not be used)
# inpainting_fill
# (too redundant with txt2img_dict)
# steps, cfg_scale, width, height, restore_faces, tiling, negative_prompt, prompt
# override_settings, override_settings_restore_afterwards, send_images, save_images,
# alwayson_scripts, batch_size, n_iter, sampler_name, seed
var img2img_dict: Dictionary = {
	"init_images": [
		# After reading the conde of the Automativ1111's web ui, it seems that 
		# this array is meant to hold 1 image in general or 1 image per image requested
		# in the batch, if there are less than the batch, the batch is resized to fit 
		# the images sent, if it's more, then error. In summary, send just one image
		# it's not worth bothering with mingling with some very custom functionality
		# unless it's an extremely specific use case like processing a video WITHOUT 
		# using controlnet or some other shennanigan like that
		"" 
	],
	"resize_mode": 0, # this is not configurable, the image will be resized in this program
	"denoising_strength": 0.7,
	"image_cfg_scale": 0,
#	"mask": "",
	"mask_blur": 3,
	"inpaint_full_res": true,
	"inpainting_mask_invert": 0,
}


func convert_to_img2img(_cue: Cue = null):
	# This function will copy all the changes made over the original request_data,
	# but only the changes that are compatible with the img2img request data
	if api.service == IMG2IMG_SERVICE:
		return # it is already img2img
	
	for key in img2img_dict.keys():
		api.request_data[key] = img2img_dict[key]
	# Also the necessary api path changes will be applied
	api.service = IMG2IMG_SERVICE


func bake_pending_img2img(_cue: Cue):
	if api.img2img_to_bake.empty():
		return
	
	convert_to_img2img()
	var resul: Dictionary = img2img_dict.duplicate()
	var height = api.request_data.get("height", 512)
	var width = api.request_data.get("width", 512)
	var base_image: Image
	for key in resul.keys():
		match key:
			"init_images":
				base_image = api.blend_images_at_dictionaries_key(
						key, api.img2img_to_bake, width, height, true, null, false
				)
#				base_image.save_png("user://img2img_base")
				# warning-ignore:return_value_discarded
				resul.erase("init_images")
				# We dont encode it as base64 because inpaint_outpaint module will do that for us
				resul[key] = [base_image] 
			"mask":
				# At the moment, there is no use for the mask in img2img thanks to the
				# dedicated tool, hence this is not used
				# Adding the comment here since these function will need an ImageData
				# as image format for the input
				resul[key] = api.blend_images_at_dictionaries_key(
						key, api.img2img_to_bake, width, height, false
						)
			"image_cfg_scale", "cfg_scale", "denoising_strength":
				resul[key] = api.average_nums_at_dictionaries_key(
						key, api.img2img_to_bake, resul[key]
						)
			_:
				resul[key] = api.overlap_values_at_dictionaries_key(
						key, api.img2img_to_bake, resul[key]
						)
	
	api.request_data.merge(resul, true)


#func bake_pending_img2img(cue: Cue):
#	# [ has_empty_space: bool = false ]
#	var has_empty_space = cue.bool_at(0, false, false)
#	if api.img2img_to_bake.empty():
#		# if there's no img2img to use as background, that means that there MAY
#		# be empty space after baking, hence why we inform it to the funcion
#		# whether or not there is empty space
#		# Important: As for right now, we can only be certain that there is empty
#		# space when using outpainting, hence this bool is set only there
#		# POSTRELEASE use Image.is_invisible() to tell if there are any empty spaces
#		# (this requires applying a shader to invert alpha channel) rather than this
#		# one-case-only workaround, also add a checkbox on outpainting and inpainting
#		# to use this feature optionally
#		api.bake_pending_mask(null, has_empty_space)
#		return
#
#	convert_to_img2img()
#	var resul: Dictionary = img2img_dict.duplicate()
#	var height = api.request_data.get("height", 512)
#	var width = api.request_data.get("width", 512)
#	var base_image
#	for key in resul.keys():
#		match key:
#			"init_images":
#				base_image = api.blend_images_at_dictionaries_key(
#						key, api.img2img_to_bake, width, height, true, null, false
#						)
##				base_image.save_png("user://img2img_base")
#				# warning-ignore:return_value_discarded
#				resul.erase("init_images")
#				api.bake_pending_mask(base_image)
#			"mask":
#				# At the moment, there is no use for the mask in img2img thanks to the
#				# dedicated tool, hence this is not used
#				# Adding the comment here since these function will need an ImageData
#				# as image format for the input
#				resul[key] = api.blend_images_at_dictionaries_key(
#						key, api.img2img_to_bake, width, height, false
#						)
#			"image_cfg_scale", "cfg_scale", "denoising_strength":
#				resul[key] = api.average_nums_at_dictionaries_key(
#						key, api.img2img_to_bake, resul[key]
#						)
#			_:
#				resul[key] = api.overlap_values_at_dictionaries_key(
#						key, api.img2img_to_bake, resul[key]
#						)
#
#	api.img2img_to_bake = []
#	api.request_data.merge(resul, true)
