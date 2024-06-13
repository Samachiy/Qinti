extends DiffusionAPIModule


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


func extract_img2img_image() -> Image:
#	var image_array = api.request_data.get("init_images", [])
#	if not image_array is Array or image_array.empty():
#		return null
#
#	var image = image_array[0]
	var image = api.request_data.get("init_images", null)
	if image is Image:
		return image
	else:
		return null


func bake_pending_mask():
	var data: Dictionary = api.get_mask_data()
	if api.img2img_to_bake.empty():
		convert_to_img2img()
	
	var base_image = data.get("init_images", '')
	var mask = data.get("mask", '')
	
	if base_image.empty():
		l.g("Can't bake pending mask, base image is empty")
		return
	
	if mask.empty():
		l.g("Can't bake pending mask, mask is empty")
		return
	
	api.request_data["init_images"] = [base_image]
	api.request_data["mask"] = mask
	if data.has("denoising_strength"):
		api.request_data["denoising_strength"] = data["denoising_strength"]
		
	
#	var img2img_image = extract_img2img_image()
#	if api.mask_to_bake.empty():
#		if api.img2img_to_bake.empty():
#			return
#		elif img2img_image is Image:
#			api.request_data["init_images"] = [ImageProcessor.image_to_base64(img2img_image)]
#			return
#		else:
#			l.g("Extracting img2img image failed when baking pending mask and no mask was queued")
#			return
#
#
##	var mask: Image = api.mask_to_bake[0]
##	var base_image: Image = api.mask_to_bake[1]
#	var mode: String = api.mask_to_bake[2]
#	if api.img2img_to_bake.empty():
#		convert_to_img2img()
#		api.request_data["init_images"] = [ImageProcessor.image_to_base64(base_image)]
#		api.request_data["mask"] = ImageProcessor.image_to_base64(mask)
#	else:
#		if not img2img_image is Image:
#			l.g("Extracting img2img image failed when baking pending mask and mask is queued")
#			return
#
#		if mode == DiffusionAPI.MASK_MODE_INPAINT:
#			base_image.blend_rect_mask(
#					img2img_image, 
#					mask, 
#					Rect2(Vector2.ZERO, img2img_image.get_size()), 
#					Vector2.ZERO
#					)
#		elif mode == DiffusionAPI.MASK_MODE_OUTPAINT:
#			api.request_data["denoising_strength"] = 1
#
##		base_image.save_png("user://inoutpaint_base.png")
##		mask.save_png("user://inoutpaint_mask.png")
#		api.request_data["init_images"] = [ImageProcessor.image_to_base64(base_image)]
#		api.request_data["mask"] = ImageProcessor.image_to_base64(mask)


#func bake_pending_mask(img2img_fill: Image, has_empty_space: bool = false):
#	# This function is meant to be called inside bake_pending_img2img()
#	if api.mask_to_bake.empty():
#		# no need to apply any mask if this is the case
#		if img2img_fill != null:
#			# We just add the original img2img if it exists
#			api.request_data["init_images"] = [ImageProcessor.image_to_base64(img2img_fill)]
#			convert_to_img2img()
#		return
#
#	convert_to_img2img()
#	# If we have to apply the mask
#	# we check if there's any need to blend or if we just apply the mask directly
#	var mask: Image = api.mask_to_bake[0]
#	var base_image: Image = api.mask_to_bake[1]
#	if img2img_fill != null:
#		# There's an image to blend (the result of the combined img2img images)
#		base_image.blend_rect_mask(
#				img2img_fill, 
#				mask, 
#				Rect2(Vector2.ZERO, img2img_fill.get_size()), 
#				Vector2.ZERO
#				)
#	else:
#		# if there's no background for the empty areas and has_empty_space
#		# we need denoising strength of 1, oterwise, we will be trying to
#		# replace noise with an empty image
#		if has_empty_space:
#			api.request_data["denoising_strength"] = 1
##	base_image.save_png("user://inoutpaint_base.png")
##	mask.save_png("user://inoutpaint_mask.png")
#	api.request_data["init_images"] = [ImageProcessor.image_to_base64(base_image)]
#	api.request_data["mask"] = ImageProcessor.image_to_base64(mask)
#	api.mask_to_bake = []
