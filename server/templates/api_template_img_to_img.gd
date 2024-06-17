extends DiffusionAPIModule


func bake_pending_img2img(has_mask: bool):
	# This function must apply pending img2img to request_data
	
	var height # <--- RETRIEVE HEIGHT FROM REQUEST_DATA AND ADD IT HERE
	var width # <--- RETRIEVE WIDTH FROM REQUEST_DATA AND ADD IT HERE
	
	var img2img_data = api.get_image_to_image_data(width, height)
	# img2img_data is a dictionary, it's values must be added to request_data. Below is 
	# an example with all the values
	
#	var img2img_dict: Dictionary = {
#		"init_images": "" # base64 image
#		"denoising_strength": 0.7,
#		"image_cfg_scale": 0,
#	}
	
	# Delete the following message once the function is ready:
	l.g("The function 'bake_pending_img2img' has not been overriden yet on Api: " + 
	name)
