class_name RepoData extends Reference

const LATEST_VER = 'LATEST_VERSION'
const STABLE_VER = 'STABLE_VERSION'

var url: String
var default_ver: String
var available_ver: Dictionary # { visible_tr_name, version string}
var latest_ver: String
var arguments: String
var amd_arguments: String
var nvidia_arguments: String
var install_available: bool
var pc: PCData = null
var class_gdscript: GDScript = null
var api_gdscript: GDScript = null
var can_install: bool = false
#var local: LocalRepo = null

# start script stuff
var start_script_linux: String = ""
var start_script_windows: String = ""
var start_args_linux: String = ""
var start_args_windows: String = ""
var start_args_amd: String = ""
var start_args_nvidia: String = ""
var start_args_intel: String = ""
var start_script_type_linux: int = type.DEFAULT_SHELL
var start_script_type_windows: int = type.DEFAULT_SHELL

enum type {
	DEFAULT_SHELL
}

func _init(pc_data_: PCData):
	pc = pc_data_
	return self


func set_start_script_linux(start_script: String, start_args: String, 
script_type: int = type.DEFAULT_SHELL) -> RepoData:
	start_script_linux = start_script.strip_edges()
	start_args_linux = start_args.strip_edges()
	start_script_type_linux = script_type
	return self


func set_start_script_windows(start_script: String, start_args: String, 
script_type: int = type.DEFAULT_SHELL) -> RepoData:
	start_script_windows = start_script.strip_edges()
	start_args_windows = start_args.strip_edges()
	start_script_type_windows = script_type
	return self


func set_start_args_amd(start_args: String) -> RepoData:
	start_args_amd = start_args.strip_edges()
	return self


func set_start_args_nvidia(start_args: String) -> RepoData:
	start_args_nvidia = start_args.strip_edges()
	return self


func set_start_args_intel(start_args: String) -> RepoData:
	start_args_intel = start_args.strip_edges()
	return self


func set_url(repo_url: String) -> RepoData:
	url = repo_url
	return self


func set_class(gdscript: GDScript):
	if gdscript.has_script_signal("repository_installed"):
		class_gdscript = gdscript
	else:
		l.g("Couldn't set class in repository data: " + url)
	
	return self


func set_api(gdscript: GDScript):
	var stop_script = DiffusionAPI
	var proving_script = gdscript
	while proving_script is GDScript:
		if proving_script == stop_script:
			api_gdscript = gdscript
			break
		else:
			proving_script = proving_script.get_base_script()
	
	if api_gdscript == null:
		l.g("Couldn't set api in repository data: " + url)
	
	return self


func set_versions(default_version: String, available_versions: Array, show_latest: bool = false, 
latest_version: String = "master") -> RepoData:
	available_ver = {}
	default_ver = default_version
	latest_ver = latest_version
	
	# The recommended ver option showuld always be present
	available_ver[STABLE_VER] = STABLE_VER
	
	for version in available_versions:
		# We add everythin in the array, no matter what it is
		if version in available_ver:
			continue
		
		available_ver[version] = version
	
	# We add it last version last so it shows at the bottom, last version tends to be unstable
	if show_latest:
		available_ver[LATEST_VER] = LATEST_VER
	
	return self


func get_start_script() -> String:
	if pc.is_linux():
		return start_script_linux
	elif pc.is_windows():
		return start_script_windows
	
	return ''


func get_start_args() -> String:
	var args = get_start_args_custom(pc)
	return args.strip_edges()


func get_start_args_custom(pc_data: PCData) -> String:
	var args = ''
	if pc_data.is_linux():
		args += start_args_linux
	elif pc_data.is_windows():
		args += start_args_windows
	
	if pc_data.is_amd():
		args += ' ' + start_args_amd
	elif pc_data.is_nvidia():
		args += ' ' + start_args_nvidia
	elif pc_data.is_intel():
		args += ' ' + start_args_intel
	
	return args
	


func get_start_args_array() -> PoolStringArray:
	return get_start_args().split(' ', false)


func get_start_script_type() -> int:
	if pc.is_linux():
		return start_script_type_linux
	elif pc.is_windows():
		return start_script_type_windows
	
	return -1


func new_local_repo(path: String):
	if class_gdscript == null:
		l.g("No set class in repository data: " + url)
		return
	
	return class_gdscript.new(path, self)


func new_api():
	if api_gdscript == null:
		l.g("No set api in repository data: " + url)
		return
	
	return api_gdscript.new()


func enable_install(value: bool):
	if class_gdscript == null:
		l.g("Can't enable install in repo '" + url + "', no class script is set")
		can_install = false
		return
	
	can_install = value
	
	return self
