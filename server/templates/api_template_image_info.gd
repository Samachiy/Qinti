extends DiffusionAPIModule


func request_image_info(_response_object: Object, _response_method: String, _image_base64: String):
	l.g("The function 'request_image_info' has not been overriden yet on Api: " + 
	name)


func get_image_info_from_result(_result) -> Dictionary:
	# Returns info formatted like a dictionary, were the keys correspond to the ones found
	# in Const.gd
	# An exception to this is:
	# 	- size (width and height) which comes in the following format:
	#		- ImageInfoController.SIZE_CONFIG_DISPLAY_NAME: {width} x {height}
	#	- others (any parameter not found in the Consts.gd) in the following format
	#		- ImageInfoController.OTHER_DETAILS_KEY: {text/string of the info}
	l.g("The function 'get_image_info_from_result' has not been overriden yet on Api: " + 
	name)
	return {}
