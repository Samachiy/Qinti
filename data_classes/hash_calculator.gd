extends Node

const CHUNK_SIZE = 1024 * 4
const QUICK_HASH_CHUNKS = 10
const COOLDOWN = 5 # seconds

var queue: Array = [] # [ [path1, object1, method1], [path2, object2, method2], ... ]
var fast_queue: Array = [] # [ [path1, object1, method1], [path2, object2, method2], ... ]
var qh_repeat_check: Dictionary = {}
var thread: Thread = null
var is_running_fast_queue: bool = false setget set_is_running_fast_queue
var is_running_queue: bool = false setget set_is_running_queue
var paused_thread: bool = false

signal fast_queue_finished
signal queue_finished
# warning-ignore:unused_signal
signal queue_next_task_request


func _ready():
	var e = connect("queue_next_task_request", self, "_run_next_queued_hash_task")
	l.error(e, l.CONNECTION_FAILED)


func set_is_running_fast_queue(value: bool):
	if is_running_fast_queue and not value:
		emit_signal("fast_queue_finished")
	
	is_running_fast_queue = value


func set_is_running_queue(value: bool):
	if is_running_fast_queue and not value:
		emit_signal("queue_finished")
	
	is_running_queue = value


func hash_file_thread(path: String, receiving_obj: Object, receiving_method: String, start: bool):
	queue.append([path, receiving_obj, receiving_method])
	if start:
		start_hashing_thread()


func hash_file_fast_thread(path: String, receiving_obj: Object, receiving_method: String, start: bool):
	fast_queue.append([path, receiving_obj, receiving_method])
	if start:
		start_hashing_thread()


func start_hashing_thread():
	paused_thread = false
	if thread == null and thread.is_alive():
		pass # We will have to wait, the thread will emit the signal 
		# to run _run_next_queued_hash_task()
	else:
		# Available, proceed with queue
		_run_next_queued_hash_task()
	
	return self


func pause_hashing_thread():
	paused_thread = true


func _run_next_queued_hash_task():
	if paused_thread:
		return
	
	l.p("new hash task queued")
	if thread is Thread and thread.is_active():
		_dispose_thread()
	
	var task_info = []
	if fast_queue.empty():
		if not queue.empty():
			task_info = queue.pop_front()
			task_info.append(0)
			is_running_queue = true
			is_running_fast_queue = false
	else:
		task_info = fast_queue.pop_front()
		task_info.append(COOLDOWN)
		is_running_queue = false
		is_running_fast_queue = true
	
	if task_info.size() < 4:
		is_running_queue = false
		is_running_fast_queue = false
		return
	
	thread = Thread.new()
	var e = thread.start(self, "_hash_file_and_send", task_info)
	l.error(e, "Error starting thread to hash file: " + str(task_info))


func _hash_file_and_send(info: Array):
	# info = [path, object, method, cooldown]
	var path = info.pop_front()
	var obj = info.pop_front()
	var method = info.pop_front()
	var cooldown = info.pop_front()
	var new_hash = hash_file(path)
	l.p(new_hash)
	if obj is Object and is_instance_valid(obj) and obj.has_method(method):
		obj.call(method, new_hash)
	
	if cooldown > 0:
		yield(get_tree().create_timer(cooldown), "timeout")
	
	call_deferred("emit_signal", "queue_next_task_request")


func _dispose_thread():
	if thread is Thread:
		thread.wait_to_finish()
		thread = null


func hash_file(path):
	var ctx = HashingContext.new()
	var file = File.new()
	# Start a SHA-256 context.
	ctx.start(HashingContext.HASH_SHA256)
	if not file.file_exists(path):
		return
	
	file.open(path, File.READ)
	# Update the context after reading each chunk.
	while not file.eof_reached():
		ctx.update(file.get_buffer(CHUNK_SIZE))
	
	# Get the computed hash.
	var res = ctx.finish()
	# Convert the hash to hexadecimal number in String
	return res.hex_encode()


func quick_hash_file(path):
	var ctx = HashingContext.new()
	var file = File.new()
	# Start a SHA-256 context.
	ctx.start(HashingContext.HASH_SHA256)
	if not file.file_exists(path):
		return
	
	file.open(path, File.READ)
	# Update the context after reading each chunk.
	for _i in range(QUICK_HASH_CHUNKS):
		if file.eof_reached():
			break
		
		ctx.update(file.get_buffer(CHUNK_SIZE))
	
	# Get the computed hash.
	var res = ctx.finish()
	# Convert the hash to hexadecimal number in String
	var hex_str = res.hex_encode()
	var hex_str_abr = hex_str.substr(0, 10)
	if qh_repeat_check.has(hex_str_abr):
		l.g("Repeated quick hash: " + str(qh_repeat_check[hex_str_abr] + " and " + str([hex_str, path])))
	else:
		qh_repeat_check[hex_str_abr] = [hex_str, path]
	
	return hex_str_abr
	
