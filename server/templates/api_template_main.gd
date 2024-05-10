extends DiffusionAPI


func _ready():
	controlnet = add_module(
			DiffusionServer.FEATURE_CONTROLNET, 
			"res://server/available_apis/auto_web_ui_control_net.gd"
	)
	# Add code here
	clear()


func clear(_cue : Cue = null): 
	# Clears the request_data back to it's original state
	l.g("The function 'clear' has not been overriden yet on Api: " + 
	name)


func generate(response_object: Object, response_method: String, custom_gen_data: Dictionary = {}):
	# custom_gen_data is meant for the retry button, so it is essentially the previous request_data
	l.g("The function 'generate' has not been overriden yet on Api: " + 
	name)
	return null


func get_images_from_result(_result, _debug: bool, _img_name: String) -> Array:
	# This function should return an array of ImageData
	# Debug will include the controlnet images sent or even print any extra data
	l.g("The function 'get_images_from_result' has not been overriden yet on Api: " + 
	name)
	return []


func get_seed_from_result(_result) -> int:
	# This function should return the seed as an int
	l.g("The function 'get_seed_from_result' has not been overriden yet on Api: " + 
	name)
	return -1


func request_progress(_response_object: Object, _response_method: String):
	l.g("The function 'request_progress' has not been overriden yet on Api: " + 
	name)
	return null


func get_progress_from_result(_result) -> float:
	# Returns progress as a float between 0.0 and 1.0, representing the percentage of progress
	# Returns 0.0 if there's no way to see the progress
	# Returns -1.0 if there's no job
	l.g("The function 'get_progress_from_result' has not been overriden yet on Api: " + 
	name)
	return 0.0


# TXT2IMG


func add_to_prompt(_cue: Cue): 
	# [positive_prompt, negative_prompt]
	# also accepts a config dictionary, will use this if the arguments are emtpy
	# the config dictionary will can be read with:
	#	var p_prompt = cue.get_option(Consts.I_PROMPT, '') 
	#	var n_prompt = cue.get_option(Consts.I_NEGATIVE_PROMPT, '')
	l.g("The function 'add_to_prompt' has not been overriden yet on Api: " + 
	name)


func replace_prompt(cue: Cue):
	# [positive_prompt, negative_prompt]
	# also accepts a config dictionary, will use this if the arguments are emtpy
	# the config dictionary will can be read with:
	#	var p_prompt = cue.get_option(Consts.I_PROMPT, '') 
	#	var n_prompt = cue.get_option(Consts.I_NEGATIVE_PROMPT, '')
	l.g("The function 'replace_prompt' has not been overriden yet on Api: " + 
	name)


func apply_parameters(_cue: Cue): 
	# the parameters lies in the cue's dictionary (aka options), those must be applied/merged to
	# request_data, they will come using the names specified in Consts.gd, so running it with
	# translate_dictionary() may be needed
	l.g("The function 'apply_parameters' has not been overriden yet on Api: " + 
	name)


func replace_parameters(_cue: Cue): 
	# the parameters lies in the cue's dictionary (aka options), request_data values must
	# be entirely replaced with those here, values that don't exist in the dictionary should 
	# not be in request_data either. Configs will come using the names specified in Consts.gd, 
	# so running it with translate_dictionary() may be needed
	l.g("The function 'replace_parameters' has not been overriden yet on Api: " + 
	name)


# SERVER MANAGEMENT


func probe_server(_current_server_address: ServerAddress):
	# checks if server is there, must signal server_probed(success: bool)
	l.g("The function 'probe_server' has not been overriden yet on Api: " + 
	name)


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
