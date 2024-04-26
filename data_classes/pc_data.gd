extends Reference

class_name PCData 


# Linux specific consts
const SEARCH_PACKAGE_COMMAND = '/usr/bin/command'
const SEARCH_PACKAGE_ARG = '-v'
const SET_PYENV_SCRIPT_LINUX = "res://dependencies/scripts/system/set_pyenv.sh"
const BASH = 'bash'
const CHMOD = 'chmod'

 # Windows specific commands
const SEARCH_COMMAND_WINDOWS = 'where'
const CMD_REDIRECT_ERROR_ARG = "2>nil"

# Specs
const OS_LINUX = 'X11'
const OS_WINDOWS = 'Windows'
const AMD_SEARCH_STRING = 'amd'
const NVIDIA_SEARCH_STRING = 'nvidia'
const INTEL_SEARCH_STRING = 'intel'
const PYTHON = 'python'
const GIT = 'git'

# Project paths
const EXE_DEPENDENCIES = "res://dependencies/exe/"

enum GPU{
	AMD,
	NVIDIA,
	INTEL,
	ERROR,
}

var os_type = ''
var gpu_type = -1
var gpu_error


# SYSTEM STUFF


func is_windows():
	if os_type.empty():
		_refresh_os()
	
	return os_type == OS_WINDOWS


func is_linux():
	if os_type.empty():
		_refresh_os()
	
	return os_type == OS_LINUX


func is_amd():
	if gpu_type == -1:
		_refresh_graphics_card()
	
	return gpu_type == GPU.AMD


func is_nvidia():
	if gpu_type == -1:
		_refresh_graphics_card()
	
	return gpu_type == GPU.NVIDIA


func is_intel():
	if gpu_type == -1:
		_refresh_graphics_card()
	
	return gpu_type == GPU.INTEL


func is_gpu_error():
	if gpu_type == -1:
		_refresh_graphics_card()
	
	return gpu_type == GPU.ERROR


func get_gpu_enum():
	if gpu_type == -1:
		_refresh_graphics_card()
	
	return gpu_type


func is_python_version(version: String):
	var output = []
	var error = OS.execute(PYTHON, ["--version"], true, output)
	l.error(error, "Couldn't execute command: python3 --version")
	return _is_succesful_output(version, output)


static func install_python_library(library: String, blocking: bool):
	#python, -m, pip, install, psutil
	var output = []
	if blocking:
		var error = OS.execute(PYTHON, ["-m", "pip", "install", library], true, output)
		l.error(error, "Couldn't install python module: " + library)
	else:
# warning-ignore:return_value_discarded
		OS.execute(PYTHON, ["-m", "pip", "install", library], false, output)
	
	

func _refresh_os():
	if OS.get_name() == OS_LINUX:
		os_type = OS_LINUX
	elif OS.get_name() == OS_WINDOWS:
		os_type = OS_WINDOWS


func _refresh_graphics_card():
	if OS.get_name() == OS_LINUX:
		gpu_type = _extract_gpu_linux()
	elif OS.get_name() == OS_WINDOWS:
		gpu_type = _extract_gpu_windows()


func _extract_gpu_linux() -> int:
	var output = []
	var error = OS.execute(BASH, ["-c", "lspci | grep -i vga"], true, output)
	l.error(error, "Error retrieving linux gpu info")
	if output.empty():
		gpu_error = "Command failed."
		return GPU.ERROR
	else:
		return _interpret_gpu(str(output[0]))


func _extract_gpu_windows() -> int:
	var output = []
	var error = OS.execute("wmic", ["path", "win32_VideoController", "get", "name"], true, output)
	l.error(error, "Error retrieving windows gpu info")
	if output.empty():
		gpu_error = "Command failed."
		return GPU.ERROR
	else:
		return _interpret_gpu(str(output[0]))


func _interpret_gpu(gpu_info: String):
	gpu_info = gpu_info.to_lower()
	if NVIDIA_SEARCH_STRING in gpu_info:
		return GPU.NVIDIA
	elif INTEL_SEARCH_STRING in gpu_info:
		return GPU.INTEL
	elif AMD_SEARCH_STRING in gpu_info:
		return GPU.AMD
	else:
		gpu_error = gpu_info
		return GPU.ERROR


static func globalize_path(path: String):
	path = path.strip_edges()
	if OS.has_feature("standalone") and "res://" == path.substr(0, 6):
		path = path.substr(6)
		return get_program_dir().plus_file(path)
	else:
		return ProjectSettings.globalize_path(path)


static func get_program_dir() -> String:
	return OS.get_executable_path().get_base_dir()


func _to_string():
	var resul = "OS: "
	if is_linux():
		resul += "Linux"
	elif is_windows():
		resul += "Windows"
	else:
		resul += "Other (" + OS.get_name() + ")"
	
	resul += ". GPU: "
	if is_amd():
		resul += "AMD"
	elif is_nvidia():
		resul += "Nvidia"
	elif is_intel():
		resul += "Intel"
	elif is_gpu_error():
		resul += "Error (" + gpu_error + ")"
	else:
		resul += "Error"
	
	return resul


static func conditional_make_dir_recursive(path: String, confirmation_dir: String):
	# return error depending of whether or not dir exist
	var dir = Directory.new()
	var error: int = OK
	if not dir.dir_exists(path):
		error = ERR_FILE_NOT_FOUND
		if dir.dir_exists(confirmation_dir):
			error = dir.make_dir_recursive(path)
	
	return error


# LINUX STUFF


func has_linux_package(package_name, output):
	var error = OS.execute(SEARCH_PACKAGE_COMMAND, 
			[SEARCH_PACKAGE_ARG, package_name], true, output)
	l.error(error, "Error executing linux package search. Package: " + 
			package_name + ". Output: " + str(output))
	return _is_succesful_output(package_name, output)


func _is_succesful_output(success_string: String, output: Array):
	var success = false
	
	for line_output in output:
		if success_string in line_output:
			success = true
			break
	
	return success


func set_up_python_ver_linux(path: String, python_ver: String) -> PythonInterface:
	DiffusionServer.set_state(Consts.SERVER_STATE_PREPARING_PYTHON)
	return Python.run(BASH, [
			globalize_path(SET_PYENV_SCRIPT_LINUX),
			path,
			python_ver,
		])


static func make_file_executable(path: String):
	var output = []
	var exit_code = OS.execute("chmod", ["+x", path], true, output)
	if not exit_code == OK:
		l.g("Error making dependency script executable with exit code " + 
				exit_code + " at: " + path)


static func make_file_executable_recursive(path: String):
	var scripts: Array = Cue.new(Consts.ROLE_FILE_PICKER, "get_file_paths").args([
				path, ".sh"
			]).execute()
	
	# Since get_file_paths is already recursive, we just need to iterate the result now
	for filename in scripts:
		make_file_executable(filename)


# WINDOWS STUFF


func has_windows_package(package_name, output = [], retrieve_error_msg: bool = true):
	var error
	if retrieve_error_msg:
		error = OS.execute(SEARCH_COMMAND_WINDOWS, [package_name], true, output)
	else:
		error = OS.execute(SEARCH_COMMAND_WINDOWS, 
				[package_name, CMD_REDIRECT_ERROR_ARG], true, output)
	l.error(error, "Error executing windows package search. Package: " + 
			package_name + ". Output: " + str(output))
	return _is_succesful_output(package_name, output)


func windows_install_python(array: Array):
	# python*.exe /quiet InstallAllUsers=1 PrependPath=1
	var exe_file = _get_executable_name(PYTHON, EXE_DEPENDENCIES)
	if exe_file.empty():
		return null
	
	var finish_notify_obj: Object = array[0]
	var finish_notify_method: String = array[1]
	var thread: Thread = array[2]
	var output = []
	var error = OS.execute(exe_file, ["/quiet", "InstallAllUsers=0", "PrependPath=1"], true, output)
	var err_msg = "Error installing python in windows. Error: " + str(error)
	if is_instance_valid(finish_notify_obj):
		if finish_notify_obj.has_method(finish_notify_method):
			finish_notify_obj.call_deferred(finish_notify_method, thread, error, err_msg, output)


func windows_install_git(array: Array):
	# Git*.exe /VERYSILENT /NORESTART
	var exe_file = _get_executable_name(GIT, EXE_DEPENDENCIES)
	if exe_file.empty():
		return null
	
	var finish_notify_obj: Object = array[0]
	var finish_notify_method: String = array[1]
	var thread: Thread = array[2]
	var output = []
	var error = OS.execute(exe_file, ["/VERYSILENT", "/NORESTART"], true, output)
	var err_msg = "Error installing git in windows. Error: " + str(error)
	if is_instance_valid(finish_notify_obj):
		if finish_notify_obj.has_method(finish_notify_method):
			finish_notify_obj.call_deferred(finish_notify_method, thread, error, err_msg, output)



func _get_executable_name(search_string: String, exe_path: String) -> String:
	var dependencies_path = globalize_path(exe_path)
	var dir = Directory.new()
	if dir.open(dependencies_path) != OK:
		l.g("An error occurred when trying to access the path.")
		return ''
	
	search_string = search_string.to_lower()
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var formated_file_name: String
	var is_file: bool = false
	var is_exe: bool = false
	var is_match: bool = false
	var result_file = ''
	while file_name != "":
		formated_file_name = file_name.to_lower()
		is_file = not dir.current_is_dir()
		is_exe = formated_file_name.get_extension() == "exe"
		is_match = search_string in formated_file_name
		if is_file and is_exe and is_match:
			result_file = file_name
			break
		
		file_name = dir.get_next()
	
	if result_file.empty():
		return ''
	else:
		return dependencies_path.plus_file(result_file)
