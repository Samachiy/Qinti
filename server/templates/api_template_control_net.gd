extends DiffusionAPIModule


func bake_pending_controlnets():
	# This function must apply the controlnet data to api.request_data, which will be used
	# as API payload for image generation
	
	# controlnet_to_bake: a dictionary with the name of the controlnet as keys and an 
	# array of dictionaries as value. the dictionaries inside the array uses names specified in 
	
	var height # <--- RETRIEVE HEIGHT FROM REQUEST_DATA AND ADD IT HERE
	var width # <--- RETRIEVE WIDTH FROM REQUEST_DATA AND ADD IT HERE
	
	var controlnet_data = api.get_controlnet_data(width, height)
	# controlnet_data is a dictionary of subdictionaries, each sub_dictionary with the values 
	# of the keys corresponding to the ones on Const.gd. Below is an example with all 
	# the values and an explanation
	
#	var controlnet_data_example = {
#	Consts.CN_TYPE_SHUFFLE: {}, # Subdictionary belonging to key "shuffle"
#	Consts.CN_TYPE_DEPTH: {}, # Subdictionary belonging to key "depth"
#	Consts.CN_TYPE_CANNY: {}, # Subdictionary belonging to key "canny"
#	Consts.CN_TYPE_LINEART: {}, # Subdictionary belonging to key "lineart"
#	Consts.CN_TYPE_MLSD: {}, # Subdictionary belonging to key "mlsd"
#	Consts.CN_TYPE_NORMAL: {}, # Subdictionary belonging to key "normal"
#	Consts.CN_TYPE_OPENPOSE: {}, # Subdictionary belonging to key "pose"
#	Consts.CN_TYPE_SCRIBBLE: {}, # Subdictionary belonging to key "scribble"
#	Consts.CN_TYPE_SEG: {}, # Subdictionary belonging to key "seg"
#	Consts.CN_TYPE_SOFTEDGE: {}, # Subdictionary belonging to key "softedge"
#	Consts.CN_TYPE_COLOR: {}, # Subdictionary belonging to key "color"
#	Consts.CN_TYPE_REFERENCE: {}, # Subdictionary belonging to key "reference"
#	}
	
#	var sub_dictionary_example: Dictionary = {
#		"input_image": "", # base64 image
#		"model": "", # Controlnet model to use (as in the .safetensors model), will appear 
#					# in all controlnets except on reference image
#		"module": "", # Only used on the reference image controlnet, otherwise, this value 
#					# will not exist
#		"weight": 1, # Strenght of the controlnet to apply
#		"guidance_start": 0, # advanced mode only
#		"guidance_end": 1, # advanced mode only
#		"control_mode": 2, # 0 = balanced, 1 = prompt more important, 2 = controlnet more important
#	}
	
	# The contents of controlnet_data must be added to request_data
	
	# Delete the following message once the function is ready:
	l.g("The function 'bake_pending_controlnets' has not been overriden yet on Api: " + 
	name)


func preprocess(response_object: Object, response_method: String, failure_method: String, 
image_data: ImageData, preprocessor_name: String):
	# This function must add the image_data and preprocessor_name into the data/payload
	# to request the preprocessed image to server
	# To retrieve the base64 enconde from image data you can use: 
	#var image_base64 = image_data.base64
	
	var api_request = APIRequest.new(response_object, response_method, self)
	api_request.connect_on_request_failed(DiffusionServer, failure_method)
	var url = api.server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	
	var data # <--- ADD THE API ENDPOINT PAYLOAD HERE
	
	api_request.api_post(url, data)
	
	# Delete the following message once the function is ready:
	l.g("The function 'preprocess' has not been overriden yet on Api: " + 
	name)


func get_preprocessed_image(result, preprocessor_name: String = '') -> ImageData:
	# Returns an ImageData
	# This function should return an ImageData, the result var will be the result 
	# created by the preprocess() function above this one. 
	# The json data will already be parsed into built-in types (like dictionary, or array, etc) 
	# before coming here
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'get_preprocessed_image' has not been overriden yet on Api: " + 
	name)
	return null
