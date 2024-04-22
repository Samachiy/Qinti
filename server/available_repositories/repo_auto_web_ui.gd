extends LocalRepo

class_name AutoWebUI_Repo

const SD_WEBUI_CONTROLNET_GIT = "https://github.com/Mikubill/sd-webui-controlnet.git"
const SD_WEBUI_CONTROLNET_NAME = "sd-webui-controlnet"

# Windows
const SEARCH_WINDOWS_PYTHON = 'python3.exe'
const SEARCH_WINDOWS_GIT = 'git.exe'
const PYTHON_VER_WINDOWS = '3.10'

# Linux
const PCKM_DNF = 'dnf'
const PCKM_DNF_DEPENDENCIES = 'sudo dnf install git python3'
const PCKM_APT = 'apt'
const PCKM_APT_DEPENDENCIES = 'sudo apt install git python3 python3-venv'
const PCKM_PACMAN = 'pacman'
const PCKM_PACMAN_DEPENDENCIES = 'sudo pacman -S git python3'
const MSG_MISSING_DEPENDENCIES = "MESSAGE_MISSING_DEPENDENCIES"
const MSG_INSTALL_PYTHON_WINDOWS = "MESSAGE_INSTALL_PYTHON_WINDOWS"
const MSG_INSTALL_GIT_WINDOWS = "MESSAGE_INSTALL_GIT_WINDOWS"
const MSG_RESTART_QINTI_NEEDED = "MESSAGE_RESTART_QINTI_NEEDED"
const MSG_INSTALL_FAILED_KEY_INPUT_DRIVERS = "MESSAGE_INSTALL_FAILED_KEY_INPUT_DRIVERS"
const PYTHON_VER_LINUX = '3.11'

var restart_needed: bool = false
var skip_python_windows: bool = false
var skip_git_windows: bool = false


func _init(path: String, repo_data: RepoData).(path, repo_data):
	pass


func _install(re_install: bool = false):
	display_log("Installing AutoWebUI Class repository.", l.DEBUG)
	
	if data.pc.is_linux():
		DiffusionServer.set_state(Consts.SERVER_STATE_INSTALLING)
		display_log("Checking dependencies", l.INFO)
		display_step(INS_STEP_CHECKING_DEPENDECIES)
		
		if not _install_linux_dependencies():
			display_step(INS_STEP_INSTALLING_DEPENDECIES)
			# if dependencies are not installed (aka not success), then return
			# A resume button will be added on the display message signal
			return

		if re_install:
			display_step(INS_STEP_RESETTING_REPO)
			yield(reset_repo(local_version), "script_finished")
			display_log("Repository finished resetting", l.DEBUG)
		else:
			display_step(INS_STEP_CLONING_REPO)
			yield(clone_repo(local_version), "script_finished")
			display_log("Repository finished cloning", l.DEBUG)
		
		yield(prepare_files(), "completed")
		
		# Setting the right python ver
		display_log("Checking python version", l.INFO)
		display_step(INS_STEP_CHECKING_PYTHON)
		if not data.pc.is_python_version(PYTHON_VER_LINUX):
			display_step(INS_STEP_PREPARING_PYTHON)
			display_log("Setting recommended python version", l.INFO)
			yield(data.pc.set_up_python_ver_linux(full_path, PYTHON_VER_LINUX), "script_finished")
			yield(data.pc.set_up_python_ver_linux(PCData.get_program_dir(), PYTHON_VER_LINUX), 
					"script_finished")
			display_log("Finished running python version script", l.DEBUG)
		
		display_step(INS_STEP_INSTALLING_SERVER)
		DiffusionServer.wait_for_server_connection()
		DiffusionServer.set_state(Consts.SERVER_STATE_INSTALLING)
		return run()
	
	elif data.pc.is_windows():
		DiffusionServer.set_state(Consts.SERVER_STATE_INSTALLING)
		# Setting the right python ver
		display_log("Checking python version", l.INFO)
		display_step(INS_STEP_CHECKING_PYTHON)
		if not skip_python_windows and not data.pc.is_python_version(PYTHON_VER_WINDOWS):
			display_step(INS_STEP_PREPARING_PYTHON)
			display_log("Setting recommended python version", l.INFO)
			pause_install_request_confirmation(
					tr(MSG_INSTALL_PYTHON_WINDOWS).format([PYTHON_VER_WINDOWS]),
					self,
					"_windows_install_python"
			)
			
			restart_needed = true
			return
		
		# Installing dependencies
		display_log("Checking dependencies", l.INFO)
		if not skip_git_windows and not data.pc.has_windows_package(SEARCH_WINDOWS_GIT):
			display_log("Installing git...", l.INFO)
			display_step(INS_STEP_INSTALLING_DEPENDECIES)
			DiffusionServer.set_state(Consts.SERVER_STATE_PREPARING_DEPENDENCIES)
			pause_install_request_confirmation(
					MSG_INSTALL_GIT_WINDOWS,
					self,
					"_windows_install_git"
			)
			
			restart_needed = true
			return
		
		if restart_needed:
			DiffusionServer.set_state(Consts.SERVER_STATE_PREPARING_DEPENDENCIES)
			pause_install_request_confirmation(
					MSG_RESTART_QINTI_NEEDED,
					self,
					"_close_setting_pending_install"
			)
			return
		
		if re_install:
			display_step(INS_STEP_RESETTING_REPO)
			yield(reset_repo(local_version), "script_finished")
			display_log("Repository resetting script finished", l.DEBUG)
		else:
			display_step(INS_STEP_CLONING_REPO)
			yield(clone_repo(local_version), "script_finished")
			display_log("Repository cloning script finished ", l.DEBUG)
		
		yield(prepare_files(), "completed")
		
		display_step(INS_STEP_INSTALLING_SERVER)
		DiffusionServer.wait_for_server_connection()
		DiffusionServer.set_state(Consts.SERVER_STATE_INSTALLING)
		return run()


func _install_linux_dependencies() -> bool:
	display_log("Installing linux dependencies repository.", l.DEBUG)
	var output = []
	var has_dependencies: bool = false
	var pc = data.pc
	has_dependencies = pc.has_linux_package(pc.PYTHON, output)
	has_dependencies = has_dependencies and pc.has_linux_package(pc.GIT, output)
	if not has_dependencies:
		DiffusionServer.set_state(Consts.SERVER_STATE_PREPARING_DEPENDENCIES)
		if pc.has_linux_package(PCKM_APT, output):
			pause_install_request_user_action(MSG_MISSING_DEPENDENCIES, PCKM_APT_DEPENDENCIES)
		elif pc.has_linux_package(PCKM_DNF, output):
			pause_install_request_user_action(MSG_MISSING_DEPENDENCIES, PCKM_DNF_DEPENDENCIES)
		elif pc.has_linux_package(PCKM_PACMAN, output):
			pause_install_request_user_action(MSG_MISSING_DEPENDENCIES, PCKM_PACMAN_DEPENDENCIES)
	
	return has_dependencies


func _windows_install_python():
	var thread = Thread.new()
	skip_python_windows = true
	# PENDING installing python MSG
	Cue.new(Consts.ROLE_SERVER_MANAGER, "cue_pause_indicator").args([false]).execute()
	thread.start(data.pc, "windows_install_python", [self, "_on_exe_install_finished", thread])


func _windows_install_git():
	var thread = Thread.new()
	skip_git_windows = true
	# PENDING installing git MSG
	Cue.new(Consts.ROLE_SERVER_MANAGER, "cue_pause_indicator").args([false]).execute()
	thread.start(data.pc, "windows_install_git", [self, "_on_exe_install_finished", thread])


func _on_exe_install_finished(thread: Thread, error: int, err_msg: String, output: Array):
	l.error(error, err_msg)
	for line in output:
		display_log(line, l.INFO)
	
	_install()
	thread.wait_to_finish()


func _close_setting_pending_install():
	full_path = '' # We set it as empty so that it doesn't get saved as an installed repo
	var cue = install_cue
	Director.add_global_save_cue(cue.role, cue.method, cue._arguments)
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "exit").execute()


func _on_script_key_input_requested():
	var log_output = l.get_content()
	var server_output = Cue.new(Consts.ROLE_SERVER_STATE_INDICATOR, "get_server_output").execute()
	var file: File = File.new()
	var error = file.open(PCData.globalize_path("res://"), File.WRITE)
	l.error(error, "Failure to create debug file when script requested key input")
	file.store_string("LOG OUTPUT:\n" + log_output + "\n\nSERVER OUTPUT:\n" + server_output)
	file.close()
	pause_install_request_user_action(MSG_INSTALL_FAILED_KEY_INPUT_DRIVERS, '')


func _on_script_finished():
	l.g("Server finished execution", l.WARNING)
	var log_output = l.get_content()
	var server_output = Cue.new(Consts.ROLE_SERVER_STATE_INDICATOR, "get_server_output").execute()
	var file: File = File.new()
	var error = file.open(PCData.globalize_path("res://failure_log.txt"), File.WRITE)
	l.error(error, "Failure to create debug file when script requested key input")
	file.store_string("LOG OUTPUT:\n" + log_output + "\n\nSERVER OUTPUT:\n" + server_output)
	file.close()
	pause_install_request_user_action(MSG_INSTALL_FAILED_KEY_INPUT_DRIVERS, '')


func prepare_files():
	if not _has_controlnet_extension():
		yield(_install_controlnet_extension(), "script_finished")
	else:
		yield(Python.get_tree(), "idle_frame")
	_enable_controlnet_extension()
	_disable_auto_launch()


func _has_controlnet_extension() -> bool:
	var extensions_dir = full_path.plus_file("extensions")
	var built_extensions_dir = full_path.plus_file("extensions-builtin")
	var controlnet_verification_file = "extract_controlnet.py"
	var dir_check: Directory = Directory.new()
	var aux: String
	var controlnet_success: bool = false
	
	# Check if it's built in
	aux = built_extensions_dir.plus_file(SD_WEBUI_CONTROLNET_NAME)
	aux = aux.plus_file(controlnet_verification_file)
	if dir_check.file_exists(aux):
		display_log("Control Net extension is instanlled as a built-in extension.", l.INFO)
		controlnet_success = true
	
	# If not built in, check if it's already installed
	if not controlnet_success:
		aux = extensions_dir.plus_file(SD_WEBUI_CONTROLNET_NAME)
		aux = aux.plus_file(controlnet_verification_file)
		# If not installed, install
		if dir_check.file_exists(aux):
			display_log("Control Net extension is instanlled.", l.INFO)
			controlnet_success = true
	
	return controlnet_success


func _install_controlnet_extension():
	var extensions_dir = full_path.plus_file("extensions")
	var controlnet_verification_file = "extract_controlnet.py"
	display_log("instanlling Control Net extension.", l.INFO)
	return clone_any_repo(
			SD_WEBUI_CONTROLNET_GIT, 
			extensions_dir, 
			"main", 
			controlnet_verification_file
	)


func _get_config_file():
	var config_json = full_path.plus_file("config.json")
	var config_dict
	var text: String
	var file = File.new()
	if not file.file_exists(config_json):
		l.g("Can't read AutoWebUI Class config file, no config.json file was found")
		return
	
	var error = file.open(config_json, file.READ)
	l.error(error, "Failure opening file: " + config_json)
	text = file.get_as_text()
	config_dict = JSON.parse(text).result
	file.close()
	return config_dict


func _set_config_file(config_dict: Dictionary):
	var file = File.new()
	var config_json = full_path.plus_file("config.json")
	file.open(config_json, File.WRITE)
	file.store_string(to_json(config_dict))
	file.close()


func _enable_controlnet_extension():
	var config_dict = _get_config_file()
	var disabled_extensions_key: String = "disabled_extensions"
	var disabled_extensions
		
	if not config_dict is Dictionary:
		l.g("Can't read AutoWebUI Class config file, config.json is not a dictionary")
		return
	
	disabled_extensions = config_dict.get(disabled_extensions_key, null)
	if not disabled_extensions is Array:
		l.g("In AutoWebUI Class config file, disabled_extensions resulted in: " + 
				str(disabled_extensions), l.WARNING)
		return
		
	if SD_WEBUI_CONTROLNET_NAME in disabled_extensions:
		display_log("Enabling Control Net extension...", l.INFO)
		disabled_extensions.erase(SD_WEBUI_CONTROLNET_NAME)
		config_dict[disabled_extensions_key] = disabled_extensions
		_set_config_file(config_dict)
		display_log("Control Net extension enabled.", l.INFO)
	else:
		display_log("Control Net extension is enabled.", l.INFO)


func _disable_auto_launch():
	var config_dict = _get_config_file()
	var auto_launch_key: String = "auto_launch_browser"
	var target_value = "Disable"
	var value
	
	if not config_dict is Dictionary:
		l.g("Can't read AutoWebUI Class config file, config.json is not a dictionary")
		return
	
	value = config_dict.get(auto_launch_key, null)
	if value is String:
		if value != target_value:
			display_log("Auto launch disabled.", l.INFO)
			config_dict[auto_launch_key] = target_value
			_set_config_file(config_dict)
	else:
		display_log("Auto launch is not present, leaving it as it is.", l.INFO)
		
