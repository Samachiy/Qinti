extends DiffusionAPIModule


func bake_pending_controlnets():
	# this must apply pending controlnet to request data
	# controlnet_to_bake: a dictionary with the name of the controlnet as keys and an 
	# array of dictionaries as value. the dictionaries inside the array uses names specified in 
	l.g("The function 'bake_pending_controlnets' has not been overriden yet on Api: " + 
	name)


func preprocess(response_object: Object, response_method: String, image_data: ImageData, 
preprocessor_name: String):
	# Returns an ImageData
	# controlnet_to_bake: a dictionary with the name of the controlnet as keys and an 
	# array of dictionaries as value. the dictionaries inside the array uses names specified in 
	l.g("The function 'preprocess' has not been overriden yet on Api: " + 
	name)


func get_preprocessed_image(result, preprocessor_name: String = '') -> ImageData:
	# Returns an ImageData
	# controlnet_to_bake: a dictionary with the name of the controlnet as keys and an 
	# array of dictionaries as value. the dictionaries inside the array uses names specified in 
	l.g("The function 'get_preprocessed_image' has not been overriden yet on Api: " + 
	name)
	return null
