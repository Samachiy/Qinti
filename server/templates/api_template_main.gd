extends DiffusionAPI


func _ready():
	
	# Add any needed code to be executed during API initialization here
	
	clear()


func load_modules():
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


func load_urls():
	# The URL and fallback URLs (if needed) that the program will connect too
	server_urls = [
	# Example:
	#		"http://127.0.0.1:7860",
	#		"http://127.0.0.1:7861",
	#		"http://127.0.0.1:7862",
	]


func reset_data(): 
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
		# Extract request_data from custom_gen_data, if the data format must not be a dictionary
		# <--- EXTRACT DATA HERE IF NEEDED
		api_request.api_post(url, custom_gen_data)
	
	# Delete the following message once the function is ready:
	l.g("The function 'generate' has not been overriden yet on Api: " + 
	name)
	return api_request


func get_images_from_result(result, debug: bool, img_name: String) -> Array:
	# This function should return an array of ImageData, the result var will be
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


func get_seed_from_result(result) -> int:
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


func get_progress_from_result(result) -> float:
	# Returns progress as a float between 0.0 and 1.0, representing the percentage of progress
	# result correspond to the result of the above function request_progress() already parsed
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


func replace_prompt(positive_prompt, negative_prompt):
	# This function will append to the positive and negastive prompt the given variables
	# If any of the prompt is null rather than String, that means that we should not replace 
	# it
	
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
#			"mask_blur": 3,
#			"inpaint_full_res": true,
#			"inpainting_mask_invert": 0, # 0 is false, 1 is true
#			"negative_prompt": "",
#			"override_settings": {
#				"CLIP_stop_at_last_layers": 1, # commonly known as clip skip
#				"sd_model_checkpoint": "model_name",
#				"sd_checkpoint_hash": "a1234", # The hash sent by the server, if any
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
	# checks if the right server is there, MUST signal server_probed(success: bool)
	# whether it succeeds or fails, and showing the resul in the bool
	
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
	# In the case this also happens in another linux distros, we apply it in ganeral rather 
	# than per OS
	api_request.api_node.timeout = 3.0
	
	api_request.api_get(url)
	# api_request.api_get(url, data) # If the endpoint is a POST, use this instead of line above
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'probe_server' has not been overriden yet on Api: " + 
	name)


func _on_probe_success(_result):
	# Notifies that the server probe succeded 
	emit_signal("server_probed", true)


func _on_prove_failed(_result):
	# Notifies that the server probe failed 
	emit_signal("server_probed", false)


func refresh_data(what_to_refresh: String):
	# refresh and sends any needed data, MUST signal data_refreshed(what_was_refreshed) 
	# where:
	#
	# what_was_refreshed: Dictionary =  { what_1: success_bool_1, what_2: success_bool_2, ... }
	#
	# what_to_refresh: String = api.REFRESH_* # it can take any of the following values
	#	api.REFRESH_ALL = "all"
	#		Refersh all of the stuff below
	#	api.REFRESH_MODELS = "diffusion models"
	#		Refersh all the diffusion models server side, then Qinti will re-read the model folder
	#	api.REFRESH_CONTROLNET_MODELS = "controlnet models"
	#		Add the list of the model names into an array and assigns it to 
	#		DiffusionServers.controlnet_models
	#	api.REFRESH_SAMPLERS = "samplers"
	#		Add the list of the model names into an array and assigns it to 
	#		DiffusionServers.samplers
	#	api.REFRESH_UPSCALERS = "upscalers"
	#		Add the list of the model names into an array and assigns it to 
	#		DiffusionServers.upscalers
	
	# For a practival example of this function, you can find one at:
	# server/available_apis/auto_web_ui_main_api.gd > refresh_data()
	
	# Delete the following message once the function is ready:
	l.g("The function 'refresh_data' has not been overriden yet on Api: " + 
	name)


# LOCAL SERVER MANAGEMENT


func get_current_diffusion_model(response_object: Object, response_method: String):
	# Gets the model in use
	
	var api_request = APIRequest.new(response_object, response_method, self)
	var url = server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	api_request.api_get(url)
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'get_current_diffusion_model' has not been overriden yet on Api: " + 
	name)
	
	
func get_diffusion_model_from_result(result: Dictionary):
	# Extracts the model from the result of the function above, must return the filename of
	# the diffusion model as a string and without the extension
	# file_name.get_basename() will remove the extension
	
	# Delete the following message once the function is ready:
	l.g("The function 'get_diffusion_model_from_result' has not been overriden yet on Api: " + 
	name)


func set_server_diffusion_model(model_file_name: String, response_object: Object, 
success_method: String, failure_method: String):
	# Sets the diffusion model
	# model_file_name will include the extension but not the path
	var api_request = APIRequest.new(response_object, success_method, self)
	api_request.connect_on_request_failed(response_object, failure_method)
	var url = server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	var data # <--- ADD THE API ENDPOINT PAYLOAD HERE
	api_request.api_post(url, data)
	
	# Delete the following message once the function is ready:
	l.g("The function 'set_server_diffusion_model' has not been overriden yet on Api: " + 
	name)


func cancel_diffusion():
	# Cancels the current image generation job server side
	
	var api_request = APIRequest.new(DiffusionServer, "_on_diffusion_canceled", self)
	var url = server_address.url + "" # <--- ADD THE API ENDPOINT HERE
	api_request.api_get(url)
	
	# if the endpoint is post, use this two lines instead
	# var data # <--- ADD THE API ENDPOINT PAYLOAD HERE
	# api_request.api_post(url, data)
	
	# Delete the following message once the function is ready:
	l.g("The function 'cancel_diffusion' has not been overriden yet on Api: " + 
	name)


func adjust_server():
	# checks configuration and configures server if needed, it MUST signal
	# adjust_server(success: bool)
	
	# The contents of this function will be highy dependant on the bakcend, some
	# will need to be configured, others not, others will need extensively. For a reference
	# of this function working in the wild, please check on:
	# server/available_apis/auto_web_ui_main_api.gd
	# 		adjust_server()
	# 		_config_check_controlnet_1() 
	# 		_config_check_controlnet_2()
	# 		_configure_server()
	# 		_on_cn_config_success()
	# 		_on_cn_config_failed()
	# All the these functions are next to each other in the reference
	
	# Delete the following message once the function is ready:
	l.g("The function 'adjust_server' has not been overriden yet on Api: " + 
	name)


func stop_server():
	# sends shutdown request to server, returns self for yield purposes, 
	# MUST emit signal server_stopped() to notify the program that it is now safe to close
	
	# Delete the following message once the function is ready:
	l.g("The function 'stop_server' has not been overriden yet on Api: " + 
	name)
	return self


func refresh_paths(_data = null):
	# Refreshes the paths of the models, must set the following variables:
	# 	DIR_LORA = ""
	# 	DIR_LYCORIS = ""
	# 	DIR_TI = ""
	# 	DIR_DIFFUSION_MODELS = ""
	# 	DIR_CONTROLNET_MODELS = ""
	# You can get the backend installation directory with get_installation_dir(), which 
	# returns an String, the directory is the backend directory, not Qinti directory
	
	# MUST signal paths_refreshed() after it is done
	
	# data could be the result of an api call, this function must have default path in case
	# data = null/''/{}/[] or whatever is set as empty argument.
	# By default, this function will only be called empty but you can call it from anywhere else
	# This is done this way because originally, the probe_server() calls for the API endpoint
	# containing the configuration, and since the result of that also contained the directories,
	# this function was then called to process and extract the paths
	
	
	# Delete the following message once the function is ready:
	l.g("The function 'refresh_paths' has not been overriden yet on Api: " + 
	name)


# DEBUG


func get_request_data_no_images(custom_data: Dictionary = {}) -> Dictionary:
	# This function should return a copy of request_data with all the parameters but
	# no images in it. If custom_data is not empty, custome_data should be used instead 
	# of request_data. 
	
	# This function exists solely for debug purposes
	
	l.g("The function 'get_request_data_no_images' has not been overriden yet on Api: " + 
	name)
	return {}


func get_request_data_no_images_no_prompts(custom_data: Dictionary = {}) -> Dictionary:
	# This function should return a copy of request_data with all the parameters but no pormpts
	# nor images in it. If custom_data is not empty, custome_data should be used instead 
	# of request_data. 
	
	# This function exists solely for debug purposes
	
	l.g("The function 'get_request_data_no_images_no_prompts' has not been overriden yet on Api: " + 
	name)
	return {}
