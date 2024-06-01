extends DiffusionAPI


func _ready():
	# Modules (add, as second argument of add_module() function, the path to script)
	# Example:
	#controlnet = add_module(
	#		DiffusionServer.FEATURE_CONTROLNET, 
	#		"res://server/available_apis/auto_web_ui_control_net.gd"
	#)
	# You can get the path by selectin it in the FileSystem inside godot (bottom
	# left corner) and pressing Control+Shift+c
	# If the server backend doesn't have the functionality related to the module, just erase
	# the corresponding add_module() function
	controlnet = add_module(
			DiffusionServer.FEATURE_CONTROLNET, 
			""
	)
	image_info = add_module(
			DiffusionServer.FEATURE_IMAGE_INFO, 
			""
	)
	img_to_img = add_module(
			DiffusionServer.FEATURE_IMG_TO_IMG, 
			""
	)
	inpaint_outpaint = add_module(
			DiffusionServer.FEATURE_INPAINT_OUTPAINT, 
			""
	)
	# Add any needed extra code here
	clear()


func clear(_cue : Cue = null): 
	clear_queues()
	# Clears the request_data back to it's original state, for example, if request data
	# is a dictionary, then:
	#	request_data = {} or request_data.clear()
	
	# Delete the following message once the function is ready:
	l.g("The function 'clear' has not been overriden yet on Api: " + 
	name)


func generate(response_object: Object, response_method: String, custom_gen_data: Dictionary = {}):
	# custom_gen_data is meant for the retry button, so it is essentially all the previous
	# request_data stored in a dictionary, it is supposed to override the request_data in
	# here.
	# Returns the ApiReqest object used to make the request to the api
	
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	api_request.connect_on_request_failed(DiffusionServer, "_on_generation_failed")
	if custom_gen_data.empty():
		api_request.api_post(url, request_data)
	else:
		# Extract request_data from custom_gen_data, if the data format should not be a dictionary
		# EXTRACT DATA HERE IF NEEDED
		api_request.api_post(url, custom_gen_data)
	
	# Delete the following message once the function is ready:
	l.g("The function 'generate' has not been overriden yet on Api: " + 
	name)
	return api_request


func get_images_from_result(_result, _debug: bool, _img_name: String) -> Array:
	# This function should return an array of ImageData, the _result var will be
	# the result created by the generate() function above this one. 
	# The json data will already be parsed into built-in types (like dictionary, or array, etc) 
	# before coming here
	
	# if debug is true, the array will include any image other than the generated images sent 
	# by the server, for exmaple, if the input controlnet images are also sent by the server, 
	# then controlnet images should be added on the resulting array. 
	# Also, if debug is true, feel free to print any extra data
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'get_images_from_result' has not been overriden yet on Api: " + 
	name)
	return []


func get_seed_from_result(_result) -> int:
	# This function should return the seed of the generated image as an int
	# The json data will already be parsed into built-in types (like dictionary, or array, etc) 
	# before coming here
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'get_seed_from_result' has not been overriden yet on Api: " + 
	name)
	return -1


func request_progress(response_object: Object, response_method: String):
	# This menthod only requieres to add the api endpoint to request the progress
	# or the image generation unless it is necessary to add extra data/information
	# in which case, also change api_request.api_get(url) into api_request.api_post(url, data)
	
	# If the backend doesn't have such an endpoint, replace all the uncommented code below with:
	# response_object.call(response_method, {})
	
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	api_request.api_get(url)
	
	# Delete the following message once the function is ready:
	l.g("The function 'request_progress' has not been overriden yet on Api: " + 
	name)


func get_progress_from_result(_result) -> float:
	# Returns progress as a float between 0.0 and 1.0, representing the percentage of progress
	# _result correspond to the result of the above function request_progress() already parsed
	# from json in in-built types
	
	# Returns 0.0 if there's no way to see the progress
	# Returns -1.0 if there's no job
	# If there was no such api endpoint to request progress, just return 0.0
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'get_progress_from_result' has not been overriden yet on Api: " + 
	name)
	return 0.0


# TXT2IMG


func add_to_prompt(positive_prompt: String, negative_prompt: String): 
	# This function will fully replace the positive and negastive prompt with the given 
	# variables, no matter if they are replacing it for an empty string. 
	
	# Delete the following message once the function is ready:
	l.g("The function 'add_to_prompt' has not been overriden yet on Api: " + 
	name)


func replace_prompt(positive_prompt: String, negative_prompt: String):
	# This function will append to the positive and negastive prompt the given variables
	
	# Delete the following message once the function is ready:
	l.g("The function 'replace_prompt' has not been overriden yet on Api: " + 
	name)


func apply_parameters(parameters: Dictionary): 
	# the parameters must be applied/merged to the request_data variable, they will come 
	# using the names specified in Consts.gd, so translating the names into the ones used 
	# by the current backend may be needed. The names of parameters use the ones from
	# Automatic1111 Web UI API
	
	# An example of the data in the dictionary:
#		var parameters = {
#			"enable_hr": false,
#			"denoising_strength": 0.7, # used hr (hi_res fix)
#			"hr_scale": 2, 
#			"hr_resize_x": 1024, # Sometimes these will not appear, but hr_scale will
#			"hr_resize_y": 1024, # Sometimes these will not appear, but hr_scale will
#			"hr_upscaler": "upscaler_name",
#			"hr_second_pass_steps": 0,
#			"prompt": "landscape", 
#			"seed": -1,
#			"sampler_name": "Euler a",
#			"batch_size": 1, # number of images to generate in a batch
#			"n_iter": 1, # number of batches
#			"steps": 20,
#			"cfg_scale": 7,
#			"width": 512,
#			"height": 512,
#			"restore_faces": false,
#			"tiling": false,
#			"negative_prompt": "",
#			"override_settings": {
#				"CLIP_stop_at_last_layers": 1, # commonly known as clip skip
#				"sd_model_checkpoint": "model_name",
#				"sd_checkpoint_hash": "a1234", # The hash sent by the server, if any, currently just used
#											# because generated images metadata tend to have it
#				"eta_noise_seed_delta": 0, # Commonly known as ENSD},
#			}
#		}
	# If you decide to omit any of the sent data, please place it in comments, if
	# what some of the values above do it's not clear, feel free to open an issue requesting
	# for more descriptions
	
	# Delete the following message once the function is ready:
	l.g("The function 'apply_parameters' has not been overriden yet on Api: " + 
	name)



func replace_parameters(parameters: Dictionary): 
	# the same as apply_paramaters() function above but with two differences
	# 1. this one will also eliminate the parameters that are not present (using the 
	# default values from the backend)
	# 2. Positive and negative prompt are also present in the parameters, the dictionary
	# keys are prompt and negative_prompt respectively
	
	# Delete the following message once the function is ready:
	l.g("The function 'replace_parameters' has not been overriden yet on Api: " + 
	name)


# SERVER MANAGEMENT


func probe_server(current_server_address: ServerAddress):
	# checks if the right server is there, must signal server_probed(success: bool) if success
	
	# ServerAddress is an object that contains possibly valid server address as well as 
	# the address that succeded in making a connection after server is probed
	server_address = current_server_address 
	
	var api_request = APIRequest.new(self, "_on_probe_success", self)
	api_request.connect_on_request_failed(self, "_on_prove_failed")
	
	# Since probing the server may fail since we are checking the server in the first
	# place, we turn off error logging. Errors will be handled instead when the 
	# emit_signal("server_probed", is_success) is fired
	api_request.push_server_down_error = false 
	api_request.print_network_error = false
	
	var url = server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	
	# Windows has a very long timeout, so as to prevent the user to be possibly waiting  
	# more than a minute to check if something is there, we set timeout at 3.0 seconds
	if Consts.pc_data.is_windows():
		api_request.api_node.timeout = 3.0
	
	api_request.api_get(url)
	# api_request.api_get(url, data) If the endpoint is a POST, use this instead of line above
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'probe_server' has not been overriden yet on Api: " + 
	name)


func _on_probe_success(result):
	# Notifies that the server probe succeded 
	emit_signal("server_probed", true)


func _on_prove_failed(_result):
	# Notifies that the server probe failed 
	emit_signal("server_probed", false)























func refresh_data(_what: String):
	# refresh and sends any needed data, must signal data_refreshed(what_signaled) where 
	# what_signaled: Dictionary =  { what_1: success_bool_1, what_2: success_bool_2, ... }
	# What: String = api.REFRESH_*
	l.g("The function 'refresh_data' has not been overriden yet on Api: " + 
	name)


# LOCAL SERVER MANAGEMENT


func get_current_diffusion_model(_response_object: Object, _response_method: String):
	# Gets the model in use
	l.g("The function 'get_server_config' has not been overriden yet on Api: " + 
	name)
	
	
func get_diffusion_model_from_result(_server_config_result: Dictionary):
	# Extracts the model from the result of the function above
	l.g("The function 'get_diffusion_model_from_result' has not been overriden yet on Api: " + 
	name)


func set_server_diffusion_model(_model_file_name: String, _response_object: Object, 
_success_method: String, _failure_method: String):
	l.g("The function 'set_server_diffusion_model' has not been overriden yet on Api: " + 
	name)


func cancel_diffusion():
	# Currently, just used to get the model in use
	l.g("The function 'cancel_diffusion' has not been overriden yet on Api: " + 
	name)


func adjust_server():
	# checks configuration and configures server if needed, must signal
	# adjust_server(success: bool)
	l.g("The function 'adjust_server' has not been overriden yet on Api: " + 
	name)


func stop_server():
	# sends shutdown request to server, returns self for yield pruposes, 
	# Must emit signal server_stopped() to notify the program that it is now safe to close
	l.g("The function 'stop_server' has not been overriden yet on Api: " + 
	name)
	return self


func refresh_paths(_data = null):
	# refresh and sends any needed path, must signal paths_refreshed() 
	# data is whatever is needed to set the appropiate paths, must have a default
	l.g("The function 'refresh_paths' has not been overriden yet on Api: " + 
	name)


# DEBUG


func get_request_data_no_images(_custom_data: Dictionary = {}) -> Dictionary:
	# This function should return an dictionary with the parameters but no images in it
	l.g("The function 'get_request_data_no_images' has not been overriden yet on Api: " + 
	name)
	return {}


func get_request_data_no_images_no_prompts(_custom_data: Dictionary = {}) -> Dictionary:
	# This function should return an dictionary with the parameters but no images nor prompts in it
	l.g("The function 'get_request_data_no_images_no_prompts' has not been overriden yet on Api: " + 
	name)
	return {}
