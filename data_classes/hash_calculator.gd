extends Node

const CHUNK_SIZE = 1024 * 4
const QUICK_HASH_CHUNKS = 10
const COOLDOWN = 5 # seconds

var queue: Array = [] # [ [path1, object1, method1], [path2, object2, method2], ... ]
var fast_queue: Array = [] # [ [path1, object1, method1], [path2, object2, method2], ... ]
var qh_repeat_check: Dictionary = {}
var thread: Thread = null

signal fast_queue_finished
signal queue_finished
signal queue_next_task_request


func _ready():
	connect("queue_next_task_request", self, "_run_next_queued_hash_task")


func thread_hash_file(path: String, receiving_obj: Object, receiving_method: String):
	queue.append([path, receiving_obj, receiving_method])
	if thread == null and thread.is_alive():
		pass # We will have to wait
	else:
		# Available, proceed with queue
		_run_next_queued_hash_task()


func _run_next_queued_hash_task():
	l.p("new has task queued")
	if thread is Thread and thread.is_active():
		_dispose_thread(thread)
	
	var task_info = []
	if fast_queue.empty():
		if not queue.empty():
			task_info = queue.pop_front()
			task_info.append(0)
	else:
		task_info = fast_queue.pop_front()
		task_info.append(COOLDOWN)
	
	if task_info.size() < 4:
		return
	
	thread = Thread.new()
	thread.start(self, "_hash_file_and_send", task_info)


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


func _dispose_thread(thread: Thread):
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
	for i in range(QUICK_HASH_CHUNKS):
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
	
