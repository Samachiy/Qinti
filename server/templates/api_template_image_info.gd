extends DiffusionAPIModule


func request_image_info(response_object: Object, response_method: String, image_base64: String):
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = api.server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	
	var data # <--- ADD THE API ENDPOINT PAYLOAD HERE
	
	api_request.api_post(url, data)
	
	# Delete the following message once the function is ready:
	l.g("The function 'request_image_info' has not been overriden yet on Api: " + 
	name)


func get_image_info_from_result(_result) -> Dictionary:
	# Returns info formatted like a dictionary, were the keys correspond to the ones found
	# in Const.gd
	# An exception to this is:
	# 	- size (width and height) which comes in the following format:
	#		- ImageInfoController.SIZE_CONFIG_DISPLAY_NAME: {width} x {height}
	#			Example: "PNG_INFO_SIZE": "512 x 512"
	#	- others (any parameter not found in the Consts.gd) in the following format
	#		- ImageInfoController.OTHER_DETAILS_KEY: {text/string of the info}
	#			Example: "PNG_INFO_OTHER": "VAE: vae.pth\n Version: 1.7.0\n"
	
	# Here is a list of Const.gd parameters commonly relevant for image info:
	# 	Consts.I_CFG_SCALE
	# 	Consts.I_DENOISING_STRENGTH
	# 	Consts.I_NEGATIVE_PROMPT
	# 	Consts.I_PROMPT
	# 	Consts.I_SAMPLER_NAME
	# 	Consts.I_SEED
	# 	Consts.I_STEPS
	# 	Consts.SDO_CLIP_SKIP
	# 	Consts.SDO_ENSD
	# 	Consts.SDO_MODEL
	# 	Consts.SDO_MODEL_HASH
	# 	Consts.T2I_ENABLE_HR
	# 	Consts.T2I_HR_SCALE
	# 	Consts.T2I_HR_RESIZE_X
	# 	Consts.T2I_HR_RESIZE_Y
	# 	Consts.T2I_HR_SECOND_PASS_STEPS
	# 	Consts.T2I_HR_UPSCALER
	# 	ImageInfoController.SIZE_CONFIG_DISPLAY_NAME
	# As long as this parameters are covered, I would say it is good enough
	
	# Small dictionary to return example:
	# var parsed_result = {
	#	Consts.I_PROMPT: "Landscape",
	#	Consts.I_NEGATIVE_PROMPT: "EasyNegative"
	#	Consts.I_SEED: 1234
	#	Consts.I_STEPS: 20
	#	ImageInfoController.SIZE_CONFIG_DISPLAY_NAME: 512 x 512
	# }
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'get_image_info_from_result' has not been overriden yet on Api: " + 
	name)
	return {}
