extends DiffusionAPIModule


func bake_pending_mask():
	# This function must apply pending img2img to request_data
	
	var data: Dictionary = api.get_mask_data()
	# data is a dictionary which values must be added to request_data. Below is 
	# an example with all the values: 
#	var data: Dictionary = {
#		"init_images": "" # base64 image
#		"mask": "" # base64 image
#		"denoising_strength": 0.7,
#	}
	
	# Also, take into account that denoising strength may not always be present, so 
	# request_data must already contain default values if said values are needed
	# for a succesful generation
	
	# Delete the following message once the function is ready:
	l.g("The function 'bake_pending_mask' has not been overriden yet on Api: " + 
	filename)
