extends DiffusionAPIModule


func bake_pending_img2img():
	# this must apply pending img2img and mask to request data
	# img2img_to_bake: an array of dictionaries with keys using the names specified in Consts.gd
	# mask_to_bake: an array of arrays with the structure: [ mask, background_for_the_masked_image ]
	l.g("The function 'bake_pending_img2img' has not been overriden yet on Api: " + 
	name)
