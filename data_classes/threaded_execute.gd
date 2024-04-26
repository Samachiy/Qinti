extends Node

# Intended for use in execution of outside programs and scripts. Inherits from node
# so as to be notified via tree of things like program closing as well as using groups
# So far it's no in use, will be used in future occasions where it is needed to execute 
# installers (git and python where already done by the time this is created)


var arguments = []
var executable_path: String = ''
var finish_notify_object: Object = null
var finish_notify_method: String = ''
var thread: Thread = null
var self_destruct: bool = false


func set(executable_path_: String, args: Array):
	if thread is Thread and thread.is_active():
		l.g("Attempted to set executable: " + executable_path_ + 
				" when thread is already running: " + executable_path)
		return
	
	executable_path = executable_path_
	arguments = args


func run(finish_notify_object_: Object, finish_notify_method_: String, free_on_finish: bool = true):
	if thread is Thread and thread.is_active():
		l.g("Can't execute: " + executable_path + ". Thread is already running.")
		return
	
	finish_notify_object = finish_notify_object_
	finish_notify_method = finish_notify_method_
	self_destruct = free_on_finish
	if finish_notify_object == null:
		l.g("Can't execute: " + executable_path + ". Object is null")
		return
	
	if finish_notify_method.empty():
		l.g("Can't execute: " + executable_path + ". Method is empty")
		return
	
	thread = Thread.new()
	thread.start(self, "_run_thread")


func _thread_run():
	var output = []
	var error = OS.execute(executable_path, arguments, true, output)
	l.error(error, "Error running " + executable_path + " in a thread. Error: " + str(error))
	call_deferred("_on_exe_install_finished", error, output)


func _on_exe_install_finished(error: int, output: Array):
	thread.wait_to_finish()
	if is_instance_valid(finish_notify_object):
		if finish_notify_object.has_method(finish_notify_method):
			finish_notify_object.call_deferred(finish_notify_method, error, output)
		else:
			l.g("Couldn't notify of execution of: " + executable_path + 
					". Object doesn't have method: " + finish_notify_method)
	else:
		l.g("Couldn't notify of execution of: " + executable_path + ". Object not valid")
	
	if self_destruct:
		queue_free()
