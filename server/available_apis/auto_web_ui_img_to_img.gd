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


func bake_pending_img2img():
	convert_to_img2img()
	var height = api.request_data.get("height", 512)
	var width = api.request_data.get("width", 512)
	var data = api.get_image_to_image_data(width, height)
	api.request_data.merge(data, true)
	api.request_data[Consts.I2I_INIT_IMAGES] = [api.request_data[Consts.I2I_INIT_IMAGES]]

