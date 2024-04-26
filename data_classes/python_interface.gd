extends Node

class_name PythonInterface

const UDP_IP = "127.0.0.1"
const UDP_PORT = 7870
const PYTHON = "python"

var server := UDPServer.new()
var script_responded: bool = false
var pids: Array = []
var is_listening: bool = false
var start_script: String
var terminate_script: String
var python_script: String
var run_script_pid: int = -1
var script_event_handler: Object = null
var prev_line_replaced: bool = false

signal output_last_line_replaced(text_line)
signal output_received(text_line)
signal script_finished
signal script_key_input_requested

func _ready():
	start_script = Consts.pc_data.globalize_path("res://dependencies/scripts/python/run.py")
	terminate_script = Consts.pc_data.globalize_path("res://dependencies/scripts/python/kill.py")
	python_script = Consts.pc_data.globalize_path("res://dependencies/scripts/system/python.sh")
	python_script = enclose_arg(python_script, '"')
	set_process(false)
#	start_listening() # for testing purposes
	pass


func _process(_delta):
# warning-ignore:return_value_discarded
	server.poll()
	if not server.is_connection_available():
		return
	
	script_responded = true
	var peer : PacketPeerUDP = server.take_connection()
	var packet
	for _i in range(peer.get_available_packet_count()):
		packet = peer.get_packet().get_string_from_utf8()
		packet = JSON.parse(packet).result
		if packet is Array:
			# packet = [type, data]
			match packet[0]:
				"DEBUG":
					l.g(packet[1], l.DEBUG)
				"SAME_LINE":
					prev_line_replaced = true
					emit_signal("output_last_line_replaced", packet[1])
				"KEY_REQUEST":
					call_on_event_handler("_on_script_key_input_requested")
					emit_signal("script_key_input_requested")
				"PID":
					pids.append(int(packet[1]))
				"END":
					call_on_event_handler("_on_script_finished")
					kill() # This has to go before emititng the signal
					# Since the signal is used to possibly start a new script
					# killing the script after emitting the signal may kill a new script
					emit_signal("script_finished")
		elif packet is String:
			if prev_line_replaced and packet.strip_edges().empty():
				pass
			elif "[A" in packet:
				pass
			else:
				emit_signal("output_received", packet)
			prev_line_replaced = false
		else:
			l.g("Packet received from python script is not of a valid type")


func add_next_line():
	if is_listening:
		prev_line_replaced = false
		emit_signal("output_received", "\n")


func start_listening():
	if is_listening:
		return
	
	is_listening = true
	var e = server.listen(UDP_PORT)
	l.error(e, "Failure to listen for UDP server responses in python script at: " + get_path())
	set_process(true)


func stop_listening():
	is_listening = false
	server.stop()
	set_process(false)


func run(command: String, args = [], event_handler: Object = null, log_level: int = l.DEBUG):
	var output: Array = []
	args = PoolStringArray(args)
	script_event_handler = event_handler
	var arguments = [enclose_arg(start_script, ''), enclose_arg(command, '')]
	arguments.append_array(args)
	
	l.g("Running: " + args_to_command(arguments), log_level)
	var pid = OS.execute(PYTHON, arguments, false, output)
	pids.append(pid)
	set_script_pid(pid)
	start_listening()
	return self


func kill():
	if pids.empty():
		return false
	
	stop_listening()
	_run_kill_command()
	pids.clear()
	run_script_pid = -1
	script_event_handler = null
	return true


func _run_kill_command():
	# For whatever reason that I can't understand, on run, it's not need to eclose
	# the path to run the python script, but here it is needed.
	# Maybe on blocking mode the arguments are not automatically enclosed?
	var arguments = [enclose_arg(terminate_script, '')]
	var output = []
	arguments.append_array(pids)
	l.g("Killing processes: " + str(pids) + ". Arguments: " + str(arguments), l.DEBUG)
	#Python.run(PYTHON, arguments)
	var exit_code = OS.execute(PYTHON, arguments, true, output)
	l.g("Processes killed, output: " + str(output), l.DEBUG)
	l.error(exit_code, "-> Exit code from kill.py")


func set_script_pid(pid: int):
	if run_script_pid != -1:
		l.g("Another program is already running with pid: " + str(run_script_pid))
		
	run_script_pid = pid


func call_on_event_handler(function_name: String, args: Array = []):
	if not is_instance_valid(script_event_handler):
		return
	
	if script_event_handler.has_method(function_name):
		script_event_handler.callv(function_name, args)


# DEPRECATED, until needed again, maybe

func enclose_arg(arg: String, enclosue = ''):
#	return arg
	return enclosue + arg + enclosue # adds dou
#	return "'" + arg + "'"
	pass


func args_to_command(args: Array) -> String:
	var resul = ''
	for arg in args:
		if ' ' in arg:
			resul += enclose_arg(arg, '"')
		else:
			resul += arg
		
		resul += ' '
	
	return resul
		
