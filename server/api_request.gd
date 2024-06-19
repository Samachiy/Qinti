extends Object

class_name APIRequest

const HEADER = ["Content-Type: application/json"]

signal api_request_processed(resul)
signal api_request_failed(response_code)
signal api_request_finished(success)

var api_node: HTTPRequest
var result = null
#var success_receivers: Array = [] # [ [object1, method1], [object2, method2], ... ]
#var failure_receivers: Array = [] # [ [object1, method1], [object2, method2], ... ]
var _success_receiving_method = ''
var _failure_receiving_method = ''
var request_url: String = ''
var request_data = ''
var push_server_down_error: bool = true
var cue_on_finish: Array = []
var cue_on_success: Array = []
var cue_on_fail: Array = []
var print_network_error: bool = true
var finish_signal_sent: bool = false
var downloading_full_file: String = ''


func _init(response_object: Object, response_method: String, parent: Node, binds: Array = []):
	api_node = HTTPRequest.new()
	parent.add_child(api_node)
	var error = api_node.connect(
			"request_completed", self, "_on_request_completed", [], CONNECT_ONESHOT)
	l.error(error, l.CONNECTION_FAILED)
	connect_on_request_processed(response_object, response_method, binds)


func _request(data, method):
	var json = JSON.print(data)
	var error = api_node.request(request_url, HEADER, true, method, json)
	
	if error != OK:
		l.g("Error: " + str(error) + ". Killing http request, no signal will be sent. " + 
				"Failed to send request to url: " + request_url + ". Method: " + 
				str(method))
		
		emit_signal("api_request_failed", -1)
		safe_free()


func api_post(url, data):
	request_url = url
	# call_deferred for yield purposes using self
	call_deferred("_request", data, HTTPClient.METHOD_POST)
	return self


func api_get(url):
	request_url = url
	# call_deferred for yield purposes using self
	call_deferred("_request", '', HTTPClient.METHOD_GET)
	return self


func download(url: String, path: String, file_name: String):
	var dir = Directory.new()
	var valid_name = file_name is String and file_name.is_valid_filename()
	var valid_dir = dir.dir_exists(path)
	if not valid_dir:
		valid_dir = dir.make_dir_recursive(path) == OK 
	
	if valid_name and valid_dir:
		api_node.timeout = 0.0
		api_node.download_chunk_size = 65536
		api_node.download_file = path.plus_file(file_name)
		var e = api_node.request(url)
		l.error(e, "Failed download request at URL: " + url)
		if e == OK:
			downloading_full_file = path.plus_file(file_name)


func cancel():
	return api_node.cancel_request()


func _print_error(text: String):
	if print_network_error:
		var extra = ''
		if l.print_debug_logs:
			extra += ". Success method: " + _success_receiving_method
			extra += ". Failure method: " + _failure_receiving_method
		
		l.g(text + extra)


func _on_request_completed(_result: int, response_code: int, 
_headers: PoolStringArray, _body: PoolByteArray):
	var failed_response = false
	var no_result = false
	if response_code == 0:
		if _result is int:
			_print_error("Connection resulted in: " + str(_result) + ". URL: " + request_url)
		if push_server_down_error:
			_print_error("Couldn't connect with server. No server found. URL: " + request_url)
			failed_response = true
	elif response_code != 200:
		_print_error("Connect with server returned error code: " + str(response_code) + 
				". URL: " + request_url)
		failed_response = true
	if _body.empty():
		no_result = true
	else:
		result = JSON.parse(_body.get_string_from_utf8()).result
	
	if no_result or failed_response:
		emit_signal("api_request_failed", response_code)
		send_cues(cue_on_fail)
		signal_finish(false)
	else:
		emit_signal("api_request_processed", result)
		send_cues(cue_on_success)
		signal_finish(true)
	
	send_cues(cue_on_finish)
	
	safe_free()


func send_cues(cue_array: Array):
	for cue in cue_array:
		if cue is Cue:
			cue.execute()


func connect_on_request_processed(response_object: Object, response_method: String, 
binds: Array = []):
	_success_receiving_method = response_method
	var error = connect(
			"api_request_processed", response_object, response_method, binds, CONNECT_ONESHOT)
	l.error(error, l.CONNECTION_FAILED)


func connect_on_request_failed(response_object: Object, response_method: String, 
binds: Array = []):
	_failure_receiving_method = response_method
	var error = connect(
			"api_request_failed", response_object, response_method, binds, CONNECT_ONESHOT)
	l.error(error, l.CONNECTION_FAILED)


func terminate():
	safe_free()


func signal_finish(success: bool):
	finish_signal_sent = true
	emit_signal("api_request_finished", success)


func safe_free():
	if not finish_signal_sent:
		# Finish signal is sent on request processed, if it wasn't sent before
		# freeing, then it was a failure
		signal_finish(false)
	
	api_node.queue_free()
	call_deferred("free")
	
