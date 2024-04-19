extends Object

class_name APISequence

var node
var steps: Array = []
var counter = 0
var id: String = ''
var mode: int 
var history: Array = [] # [ 1, 1, 0, 1 ] Example: 1st, 2nd and 4th step success, 3rd failed

var filter: int = run_filters.ALL # this will use the history
var recheck_untried: bool = false
var pending_force_stop: bool = false

enum {
	NO_STOP,
	STOP_IF_FAILURE,
	STOP_IF_SUCCESS
}

enum run_filters {
	ALL,
	SUCCESS_ONLY,
	FAILURE_ONLY,
	UNTRIED_ONLY,
}

signal sequence_finished(sequence_id)

func _init(target_node: Node, sequence_id: String, stop_mode: int):
	# sequence_id is used to save the succesfull step of the sequence to go there directly
	# after a new program start
	node = target_node
	id = sequence_id
	mode = stop_mode


func add_post(url, data, target_method_success: String, target_method_failure: String = ''):
	var api_request = _new_api_request(target_method_success, target_method_failure)
	var step = APIStep.new(api_request)
	step.set_http_post(url, data)
	steps.append(step)
	return api_request


func add_get(url, target_method_success: String, target_method_failure: String = ''):
	var api_request = _new_api_request(target_method_success, target_method_failure)
	var step = APIStep.new(api_request)
	step.set_http_get(url)
	steps.append(step)
	return api_request


func _new_api_request(target_method_success: String, target_method_failure: String) -> APIRequest:
	var api_request = APIRequest.new(node, target_method_success, node, [self])
	if not target_method_failure.empty():
		api_request.connect_on_request_failed(node, target_method_failure, [self])
	
	api_request.connect_on_request_processed(self, "_on_step_success", [self])
	api_request.connect_on_request_failed(self, "_on_step_failure", [self])
	# The last connect is registered inside api_request for debuggin purposes, but we need this
	# object to receive the connections last so as to allow manual stopping. As a result, we 
	# manually set the debug info here:
	api_request._success_receiving_method = target_method_success
	api_request._failure_receiving_method = target_method_failure
	
	return api_request


func _try_next_step():
	match filter:
		run_filters.ALL:
			counter += 1
		run_filters.SUCCESS_ONLY:
			counter = _get_next_history_success()
		run_filters.FAILURE_ONLY:
			counter = _get_next_history_success()
		run_filters.UNTRIED_ONLY:
			counter = _get_next_untried()
	
	if counter < steps.size():
		var step: APIStep = steps[counter]
		step.try()
	elif recheck_untried:
		recheck_untried = false # stopping condition
		filter = run_filters.UNTRIED_ONLY
		run()
	else:
		finish()


func _get_next_history_success():
	var i = counter
	if i < 0:
		i = 0
	
	while i < history.size() and history[i] == 0:
		i += 1
	
	return i


func _get_next_history_failure():
	var i = counter
	if i < 0:
		i = 0
	
	while i < history.size() and history[i] == 1:
		i += 1
	
	return i


func _get_next_untried():
	var i = counter
	if i < 0:
		i = 0
	
	var step: APIStep
	while i < steps.size():
		step = steps[i]
		if step.tried:
			i += 1
		else:
			break
	
	return i


func _on_step_success(_result, _api_sequence: APISequence):
	history.append(1)
	if pending_force_stop:
		finish()
		return
	
	match mode:
		NO_STOP, STOP_IF_FAILURE:
			_try_next_step()
		STOP_IF_SUCCESS:
			finish()


func _on_step_failure(_response, _api_sequence: APISequence):
	history.append(0)
	if pending_force_stop:
		finish()
		return
	
	match mode:
		NO_STOP, STOP_IF_SUCCESS:
			_try_next_step()
		STOP_IF_FAILURE:
			finish()


func finish():
	if not id.empty():
		DiffusionServer.sequences_data[id] = history
	
	emit_signal("sequence_finished", id)
	call_deferred("free")


func force_stop():
	pending_force_stop = true


func run():
	if steps.empty():
		return
	
	counter = -1 # try next step will add counter + 1 before trying, hence we start at -1
	_try_next_step()


func run_success(try_all_if_failure: bool):
	history = DiffusionServer.sequences_data.get(id, [])
	if history.empty():
		if try_all_if_failure:
			run()
	else:
		if try_all_if_failure:
			recheck_untried = true
		
		filter = run_filters.SUCCESS_ONLY
		run()


class APIStep extends Reference:
	var api_request: APIRequest = null
	var http_method: int
	var url: String
	var data
	var tried: bool = false
	
	func _init(api_request_):
		api_request = api_request_
		return self
	
	
	func set_http_post(url_: String, data_):
		http_method = HTTPClient.METHOD_POST
		data = data_
		url = url_
		return self
	
	
	func set_http_get(url_: String):
		http_method = HTTPClient.METHOD_GET
		url = url_
		return self
	
	
	func try(retry: bool = false):
		if tried and not retry:
			return
		
		tried = true
		match http_method:
			HTTPClient.METHOD_POST:
				api_request.api_post(url, data)
			HTTPClient.METHOD_GET:
				api_request.api_get(url)
