extends Reference

# Contains a local path and a RepoData, will manage the local repository at the specific path
# RepoData doesn't handle paths, LocalRepo does

class_name LocalRepo

const GIT = 'git'

# Generic installaion steps
const INS_STEP_CHECKING_DEPENDECIES = "INS_STEP_CHECKING_DEPENDECIES"
const INS_STEP_INSTALLING_DEPENDECIES = "INS_STEP_INSTALLING_DEPENDECIES"
const INS_STEP_CLONING_REPO = "INS_STEP_CLONING_REPO"
const INS_STEP_RESETTING_REPO = "INS_STEP_RESETTING_REPO"
const INS_STEP_CHECKING_PYTHON = "INS_STEP_CHECKING_PYTHON"
const INS_STEP_PREPARING_PYTHON = "INS_STEP_PREPARING_PYTHON"
const INS_STEP_INSTALLING_SERVER = "INS_STEP_INSTALLING_SERVER"

var data: RepoData = null
var repo_name: String = ""
var clone_path: String = ""
var full_path: String = ""

var clone_repo_script_linux: String
var clone_repo_script_windows: String
var reset_repo_script_linux: String
var reset_repo_script_windows: String

var local_version: String = '' setget _set_local_version
var is_installed: bool = false setget _set_is_installed
var install_cue: Cue = null # Intended for resuming install if the program needs to close
var args_override: String = ''
var extra_args: String = ''

# warning-ignore:unused_signal
signal repository_installed(local_repo)
signal run_started

func _init(path: String, repo_data: RepoData):
	data = repo_data
	clone_repo_script_linux = PCData.globalize_path(
			"res://dependencies/scripts/system/clone_repo.sh")
	clone_repo_script_windows = PCData.globalize_path(
			"res://dependencies/scripts/system/clone_repo.bat")
	reset_repo_script_linux = PCData.globalize_path(
			"res://dependencies/scripts/system/reset_repo.sh")
	reset_repo_script_windows = PCData.globalize_path(
			"res://dependencies/scripts/system/reset_repo.bat")
	local_version = data.default_ver
	
	if has_start_script(path):
		# This is in case the repository is already cloned
		self.is_installed = true
		
		# We remove the final \ (linux) or / (windows)
		full_path = path.plus_file('').get_base_dir() 
		
		repo_name = full_path.get_file()
		clone_path = full_path.get_base_dir()
	else:
		# This is in case the repository is pending cloning
		self.is_installed = false
		clone_path = path
		if not repo_data.url.empty():
			repo_name = repo_data.url.get_basename().get_file()
			full_path = clone_path.plus_file(repo_name)
		else:
			l.g("The LocalRepo '" + data.id + 
					"' doesn't have a git url assigned, repository operations won't be possible")


func has_start_script(dir_path):
	var dir: Directory = Directory.new()
	return dir.file_exists(dir_path.plus_file(data.get_start_script()))


static func extract_git_origin(full_repo_path: String) -> String:
	var output = []
	var error = OS.execute(GIT, 
			["-C", full_repo_path, "ls-remote", "--get-url", "origin"], true, output)
	l.error(error, "Error retrieving git origin at: " + full_repo_path)
	if output.empty():
		return ''
	else:
		return str(output[0]).strip_edges()


static func extract_readme_title(full_repo_path: String) -> String:
	var readme = "README.md"
	var readme_path = full_repo_path.plus_file(readme)
	var title = ''
	var file: File = File.new()
	var error = file.open(readme_path, File.READ)
	l.error(error, "Failed to open file: " + readme_path)
	if error == OK:
		var line 
		var title_indicator = "#"
		while not file.eof_reached():
			line = file.get_line()
			line = line.strip_edges()
			if not line.empty() and line[0] == title_indicator:
				title = line
				break
	
	return title


static func get_repo_data_from_array(full_repo_path: String, repo_data_array: Array) -> RepoData:
	var git_repo_url = extract_git_origin(full_repo_path).to_lower()
	var repo_data_url: String
	for repo_data in repo_data_array:
		if not repo_data is RepoData:
			continue
		
		repo_data_url = repo_data.url.strip_edges()
		if repo_data_url.to_lower() == git_repo_url:
			return repo_data
	
	# If this doesn't return, that means looking at git origin failed
	var title = extract_readme_title(full_repo_path).to_lower()
	var repo_title: String
	for repo_data in repo_data_array:
		if not repo_data is RepoData:
			continue
		
		repo_title = repo_data.readme_title.strip_edges()
		if repo_title.empty():
			l.g("Repository: " + repo_data.url + " doesn't have a readme title")
		elif repo_title.to_lower() == title:
			return repo_data
	
	return null


static func new_from_repo_array(full_repo_path: String, repo_data_array: Array) -> LocalRepo:
	var repo_data: RepoData = get_repo_data_from_array(full_repo_path, repo_data_array)
	return new_from_data(full_repo_path, repo_data)


static func new_from_data(full_repo_path: String, repo_data) -> LocalRepo:
	if repo_data == null:
		return null
	
	if repo_data.class_gdscript is GDScript:
		return repo_data.class_gdscript.new(full_repo_path, repo_data)
	else:
		return null
	


func override_args(new_args: String, append_to_base_args: bool):
	if append_to_base_args:
		args_override = data.get_start_args() + ' '
	else:
		args_override = ''
	
	extra_args = new_args
	args_override += new_args


func reset_repo(repo_version: String) -> PythonInterface:
	if repo_name.empty():
		l.g("LocalRepo '" + data.id + "' doesn't have a git url, reset won't be possible")
		
	# Allows to specify version
	l.g("Reseting repository: " + repo_name + ". Ver.: " + repo_version, l.INFO)
	var script
	var os_clone_path: String = clone_path # os dependant clone path
	if data.pc.is_linux():
		script = reset_repo_script_linux
	elif data.pc.is_windows():
		script = reset_repo_script_windows
		os_clone_path = clone_path.replace("/", "\\")
	
	return Python.run(script, [
			os_clone_path,
			repo_name,
			data.url,
			repo_version,
			data.get_start_script()
		])


func clone_repo(repo_version: String) -> PythonInterface:
	if repo_name.empty():
		l.g("LocalRepo '" + data.id + "' doesn't have a git url, reset won't be possible")
		
	# Will only clone repo if needed
	l.g("Cloning repository: " + repo_name, l.INFO)
	return clone_any_repo(data.url, clone_path, repo_version, data.get_start_script(), repo_name)


func clone_any_repo(git_url: String, repository_clone_path: String, repository_version: String, 
verification_file: String, repository_name: String = '') -> PythonInterface:
	if repository_name.empty():
		repository_name = git_url.get_basename().get_file()
	
	var script
	if data.pc.is_linux():
		script = clone_repo_script_linux
	elif data.pc.is_windows():
		script = clone_repo_script_windows
		repository_clone_path = repository_clone_path.replace("/", "\\")
	
	return Python.run(script, [
			repository_clone_path,
			repository_name,
			git_url,
			repository_version,
			verification_file
		])
	


func _set_is_installed(value: bool):
	if is_installed == value:
		return
	
	is_installed = value
	if is_installed:
		emit_signal("repository_installed", self)


func _set_local_version(version: String):
	if data == null:
		l.g("Can't set local version '" + version + "', no repo data found")
		return
	
	var success = false
	match version:
		data.LATEST_VER:
			version = data.latest_ver
		data.STABLE_VER:
			version = data.default_ver
	
	if version == data.default_ver:
		success = true
	elif version == data.latest_ver:
		success = true
	elif version in data.available_ver:
		success = true
	
	if success:
		local_version = version
	else:
		local_version = data.default_ver
		l.g("Can't set local version '" + version + 
				"', version doesn't exist, setting to defaul version")


func install(re_install: bool = false):
	if data.can_install:
		stop_load_icon_if_no_output(true)
		DiffusionServer.set_state(Consts.SERVER_STATE_INSTALLING)
		_install(re_install)


func pause_install_request_user_action(text: String, code_to_copy: String):
	Cue.new(Consts.ROLE_DIALOGS, "request_user_action").args([
			text,
			code_to_copy]).execute()
	
	Cue.new(Consts.ROLE_SERVER_MANAGER, "cue_pause_indicator").args([true]).execute()


func pause_install_request_confirmation(text: String, object: Object, method: String, 
args: Array = []):
	Cue.new(Consts.ROLE_DIALOGS, "request_confirmation").args([
			text,
			object,
			method,
			args]).execute()
	
	Cue.new(Consts.ROLE_SERVER_MANAGER, "cue_pause_indicator").args([true]).execute()


func _on_install_script_finished():
	# Not currently in use
	l.g("Install script finished.", l.INFO)
	if DiffusionServer.get_state() == DiffusionServer.STATE_STARTING:
		l.g("Install process was halted during server run, restarting.", l.INFO)
# warning-ignore:return_value_discarded
		run()
	


func _install(_re_install: bool = false):
	# This must return a PythonInterface running the installed server if it works, 
	# null if it doesn't
	l.g("Install repository hasn't been overridden in  " + repo_name)


func prepare_files():
	# This configures the necessary local files before running
	l.g("Prepare repository files hasn't been overridden in  " + repo_name)


func _on_script_key_input_requested():
	# When the run script requests an input, this function will be called
	l.g("'_on_script_key_input_requested' hasn't been overridden in  " + repo_name)


func run() -> PythonInterface:
	if repo_name.empty():
		l.g("LocalRepo '" + data.id + 
				"' doesn't have a repo_name, error running. Please contact developer.")
		
	# Will return null if it fails, otherwise, a PythonInterface
	prepare_files()
	l.g("Running repository: " + repo_name, l.INFO)
	var script_type = data.get_start_script_type()
	if DiffusionServer.get_state() == DiffusionServer.STATE_INSTALLING:
		stop_load_icon_if_no_output(false)
	DiffusionServer.set_state(Consts.SERVER_STATE_STARTING)
	match script_type:
		data.type.DEFAULT_SHELL:
			return _run_shell()
		_: 
			l.g("Can't run local repo '" + data.url + "' no adecuate script type is set. PC -> " 
					+ str(data.pc))
			return null


func _run_shell() -> PythonInterface:
	var final_args = []
	var start_script = data.get_start_script()
	if start_script.empty():
		l.g("Can't run local repo '" + data.url + "' no start script found. PC: " 
				+ str(data.pc))
		return null
	
	start_script = full_path.plus_file(start_script)
	var dir: Directory = Directory.new()
	if not dir.file_exists(start_script):
		l.g("Can't run local repo '" + data.url + "' start script file doesn't exist. PC:" 
				+ str(data.pc))
		return null
	
	if args_override.empty():
		final_args.append_array(data.get_start_args_array())
	else:
		final_args.append_array(args_override.split(' ', false))
	
	DiffusionServer.running_repo = self
	l.g("Repository script type: Shell. At: " + start_script, l.DEBUG)
	l.g("Arguments: " + str(final_args) + "PC: " + str(data.pc), l.DEBUG)
	if data.pc.is_linux():
		return Python.run(start_script, final_args, self, l.INFO)
		pass
	elif data.pc.is_windows():
		return Python.run(start_script, final_args, self, l.INFO)
		pass
	
	return null


func display_step(text: String):
	Cue.new(Consts.ROLE_SERVER_MANAGER, "set_install_step").args([text]).execute()


func display_log(text, log_level = -1):
	# log_level == -1 means no loggingwill be done
	if log_level != -1:
		l.g(text, log_level)
	
	Cue.new(Consts.ROLE_SERVER_MANAGER, "cue_text_to_console").args([text]).execute()


func stop_load_icon_if_no_output(stop: bool, time: int = 30):
	Cue.new(Consts.ROLE_SERVER_MANAGER, "cue_icon_stop_if_no_output").args([stop, time]).execute()

