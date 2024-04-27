extends Panel

const LINUX = "LINUX"
const WINDOWS = "WINDOWS"
const AMD = "AMD"
const NVIDIA = "NVIDIA"
const UI_CHANGE_TIME = 0.2

const MSG_INVALID_PATH_NO_INSTALL_FOUND = "MESSAGE_INVALID_PATH_NO_INSTALL_FOUND"
const MSG_NO_NETWORK_CONNECTION = "MESSAGE_NO_NETWORK_CONNECTION"
const MSG_INVALID_SERVER_URL = "MESSAGE_INVALID_SERVER_URL"
const MSG_BETA_FEATURE_CONTINUE = "MESSAGE_BETA_FEATURE_CONTINUE"

onready var local_backend = $LocalBackend
onready var install_path = $"%InstallPath"
onready var selected_installation_path = $"%SelectedInstallationPath"
onready var install_args = $"%InstallArguments"
onready var selected_installation_args = $"%OpenArguments"
onready var install_core_args = $"%CoreInstallArguments"
onready var selected_installation_core_args = $"%CoreOpenArguments"
onready var remote_server_url = $"%ConnectToServerURL"
onready var available_os = $"%AvailableOS"
onready var available_gpu_install = $"%InstallAvailableGPU"
onready var available_gpu_open = $"%OpenAvailableGPU"
onready var available_servers_open = $"%OpenAvailableServers"
onready var available_servers = $"%InstallAvailableServers"
onready var available_server_ver = $"%InstallAvailableServerVersions"
#onready var info_dialog = $InfoDialog
#onready var confirm_dialog = $ConfirmationDialog
onready var install_option_ui = $InstallOption
onready var choose_installed_option_ui = $ChooseInstalledDirOption
onready var remote_server_option_ui = $RemoteServerOption
onready var main_options_ui = $MainOptions
onready var main_options_exit = $"%ExitInstallerButton"
onready var instal_proc_output = $"%InstallationOutput"
onready var instal_proc_resume = $"%ResumeInstallation"
onready var instal_proc_step = $"%InstallationStep"
onready var instal_proc_load_icon = $"%InstallationLoadingIcon"
onready var instal_proc_load_icon_space = $"%InstallationLoadingIconSpace"
onready var instal_proc_load_icon_timer = $"%InstallationLoadingIconTimer"
onready var instal_proc_ui = $InstallingDialog
onready var instal_proc_finish = $"%InstallationFinish"
onready var languages = $"%Language"

var hide_on_back = []
var prev_server_address = ''
var text_output_to_console: bool = true
var stop_load_icon_if_no_output: bool = false

#signal installation_folder_changed(path)


func _ready():
	# Setting componentes visibility
	instal_proc_resume.visible = false
	instal_proc_load_icon.visible = false
	instal_proc_step.visible = true
	instal_proc_load_icon_space.visible = true
	
	# Setting menus visibility
	main_options_ui.visible = true
	main_options_exit.visible = false
	remote_server_option_ui.visible = false
	choose_installed_option_ui.visible = false
	install_option_ui.visible = false
	instal_proc_ui.visible = false
	
	# Setting individual elements visibility
	available_servers_open.visible = false
	available_servers_open.get_parent().visible = false
	
	Roles.request_role(self, Consts.ROLE_SERVER_MANAGER)
	Director.use_up_locker(Consts.ROLE_SERVER_MANAGER)
	Director.connect_global_save_cues_requested(self, "_on_global_save_cues_requested")
	available_os.add_labeled_item(LINUX, LINUX)
	available_os.add_labeled_item(WINDOWS, WINDOWS)
	if Consts.pc_data.is_linux():
		available_os.select_by_label(LINUX)
	elif Consts.pc_data.is_windows():
		available_os.select_by_label(WINDOWS)
	
	populate_available_gpu()
	
	var server_info: RepoData
	for server_type in local_backend.servers:
		server_info = local_backend.servers[server_type]
		if server_info.can_install:
			available_servers.add_labeled_item(server_type, server_type)
		available_servers_open.add_labeled_item(server_type, server_type)
		
	available_servers.select_first()
	
	var e = Python.connect("output_received", self, "_on_PythonInterface_output_received")
	l.error(e, l.CONNECTION_FAILED)
	e = Python.connect("output_last_line_replaced", self, "_on_PythonInterface_last_line_replaced")
	l.error(e, l.CONNECTION_FAILED)
	refresh_versions()
	refresh_locale()
	e = UIOrganizer.connect("locale_changed", self, "_on_locale_changed")
	l.error(e, l.CONNECTION_FAILED)


func populate_available_gpu():
	available_gpu_install.add_labeled_item(AMD, AMD)
	available_gpu_install.add_labeled_item(NVIDIA, NVIDIA)
	available_gpu_open.add_labeled_item(AMD, AMD)
	available_gpu_open.add_labeled_item(NVIDIA, NVIDIA)
	var gpu_enum = Consts.pc_data.get_gpu_enum()
	if gpu_enum == PCData.GPU.AMD:
		available_gpu_install.select_by_label(AMD)
		available_gpu_open.select_by_label(AMD)
	else:
		available_gpu_install.select_by_label(NVIDIA)
		available_gpu_open.select_by_label(NVIDIA)


func refresh_versions():
	# refreshes the versions available for install in the combobox
	var selected_server = available_servers.get_selected()
	var server_details: RepoData = local_backend.servers.get(selected_server)
	available_server_ver.clear()
	if not server_details is RepoData:
		return
	
	var server_versions: Dictionary = server_details.available_ver
	if not server_versions is Dictionary:
		return
	
	for version in server_versions.keys():
		available_server_ver.add_labeled_item(version, server_versions[version])
	
	available_server_ver.select_by_label(RepoData.STABLE_VER)
	
	# We hide the server version if there's only one just for aesthetic purposes
	if available_server_ver.get_item_count() <= 1:
		available_server_ver.get_parent().visible = false
	else:
		available_server_ver.get_parent().visible = true


func refresh_locale():
	for language_str in Locale.available:
		if language_str is String:
			languages.add_labeled_item(language_str.to_upper(), language_str)
	
	languages.select_by_label(TranslationServer.get_locale(), true, false)


func _on_locale_changed(locale: String):
	languages.select_by_label(locale, true, false)


func _on_ProceedRemoteServer_pressed():
	# Change the URL in diffusion server
	# POSTRELEASE
	prev_server_address = DiffusionServer.server_address
	DiffusionServer.server_address = remote_server_url.text
	DiffusionServer.test_server(self, "_on_connection_succesful", "_on_connection_failed")


func _on_connection_succesful(_result):
	hide_installation_window()


func _on_connection_failed(response_code):
	DiffusionServer.server_address = prev_server_address
	if response_code == 0:
		Cue.new(Consts.ROLE_DIALOGS, "request_user_action").args([
				MSG_NO_NETWORK_CONNECTION]).execute()
	else:
		Cue.new(Consts.ROLE_DIALOGS, "request_user_action").args([
				MSG_INVALID_SERVER_URL]).execute()


func _on_ProceedOpenInstalled_pressed():
	var success = false
	var path = selected_installation_path.text
	# load_installation_folder_info already checks if folder exists
	if load_installation_folder_info(path):
		if local_backend.repo.is_installed:
			success = true
	elif available_servers_open.visible and \
	load_installation_folder_info_manual_server(available_servers_open.get_selected(), path):
		if local_backend.repo.is_installed:
			l.g("Manual backend was applied: " + local_backend.repo.data.id, l.INFO)
			success = true
	else:
		available_servers_open.visible = true
		available_servers_open.get_parent().visible = true
		available_servers_open.select_first()
	
	if success:
		set_gpu_in_pcdata(local_backend.repo.data.pc, available_gpu_open.get_selected())
		local_backend.repo.override_args(selected_installation_args.text, true)
		hide_installation_window()
		yield(local_backend.repo.prepare_files(), "completed")
		if DiffusionServer.get_state() != Consts.SERVER_STATE_READY:
			DiffusionServer.initialize_server_connection()
	else:
		local_backend.repo = null
		Cue.new(Consts.ROLE_DIALOGS, "request_user_action").args([
				MSG_INVALID_PATH_NO_INSTALL_FOUND]).execute()


func set_installation_info(cue: Cue):
	# [ global_full_repo_path: String, gpu_type: int, extra_args: String ]
	var path = cue.str_at(0, '')
	var gpu_type = cue.int_at(1, PCData.GPU.NVIDIA)
	var extra_args = cue.str_at(2, '')
	var success = load_installation_folder_info(path)
	
	if success:
		local_backend.repo.data.pc.gpu_type = gpu_type
		local_backend.repo.override_args(extra_args, true)
		DiffusionServer.initialize_server_connection()
		hide_installation_window()
	
	var backend = cue.str_option("backend", '')
	success = load_installation_folder_info_manual_server(backend, path)
	if success:
		l.g("Manual backend was applied: " + local_backend.repo.data.id, l.INFO)
		local_backend.repo.data.pc.gpu_type = gpu_type
		local_backend.repo.override_args(extra_args, true)
		DiffusionServer.initialize_server_connection()
		hide_installation_window()


func set_install_cue(cue: Cue):
	# [ global_full_repo_path, gpu_label, server_label, version_label ]
	var path = cue.str_at(0, '')
	var gpu_label = cue.str_at(1, available_gpu_install.get_selected())
	var server_label = cue.str_at(2, available_servers.get_selected())
	var version_label = cue.str_at(3, available_server_ver.get_selected())
	install_path.text = path
	available_gpu_install.select_by_label(gpu_label)
	available_servers.select_by_label(server_label)
	available_server_ver.select_by_label(version_label)
	_on_ProceedInstall_pressed()


func get_install_cue(_cue: Cue = null):
	var path = install_path.text
	var gpu_label = available_gpu_install.get_selected()
	var server_label = available_servers.get_selected()
	var version_label = available_server_ver.get_selected()
	path = install_path.text
	return Cue.new(Consts.ROLE_SERVER_MANAGER, "set_install_cue").args(
			[path, gpu_label, server_label, version_label])


func load_installation_folder_info(path: String):
	l.g("Loading server installed at: " + path, l.INFO)
	var repo = get_repo_from_path(path)
	return load_repo(repo, path)


func load_installation_folder_info_manual_server(server_id: String, path: String):
	if not server_id.empty():
		var repo_data: RepoData = local_backend.servers.get(server_id, null)
		return load_repo(LocalRepo.new_from_data(path, repo_data), "[Manual selected repo]")
	else:
		return false


func load_repo(repo: LocalRepo, debug_path: String):
	if repo == null:
		l.g("The path '" + debug_path + "' doesn't contain a valid repository")
		return false
	else:
		_prepare_repo(repo)
		return true
	


func get_repo_from_path(path: String, error_level: int = l.ERROR) -> LocalRepo:
	if path.empty():
		l.g("Can't read installation folder info, path is empty: " + path, error_level)
		return null
	
	var dir: Directory = Directory.new()
	if not dir.dir_exists(path):
		l.g("Can't read installation folder info, folder doesn't exist: " + path, error_level)
		return null
	
	return LocalRepo.new_from_repo_array(path, local_backend.servers.values())


func _on_ProceedInstall_pressed():
	var dir = Directory.new()
	var dir_path = install_path.text
	var error = OK
	if dir_path.empty():
		return
	
	if not dir.dir_exists(dir_path):
		error = dir.make_dir_recursive(dir_path)
		if error != OK:
			l.g("Invalid install path: " + dir_path)
			return
	
	# I assume this should check for permissions
	error = dir.open(dir_path)
	if error != OK:
		l.g("Can't open path: " + dir_path)
		return
	
	l.g("Getting repository information to install at: " + dir_path, l.DEBUG)
	var server_id = available_servers.get_selected()
	var repo_data: RepoData = local_backend.servers.get(server_id, null)
	if repo_data == null:
		l.g("Repository id " + str(server_id) + "wasn't found in available servers")
		return
	
	var repo: LocalRepo = repo_data.new_local_repo(dir_path)
	if repo == null:
		l.g("Repository wasn't found in available servers")
		return 
	
	text_output_to_console = true
	repo.local_version = available_server_ver.get_selected()
	set_gpu_in_pcdata(repo.data.pc, available_gpu_install.get_selected())
	repo.override_args(install_args.text, true)
	set_pause_indicator(false)
	show_installation_progress()
	var e = DiffusionServer.connect("server_ready", self, "_on_Installation_completed")
	l.error(e, l.CONNECTION_FAILED)
	_prepare_repo(repo)
	repo.install_cue = get_install_cue()
	repo.install()


func _on_Installation_completed():
	instal_proc_load_icon.stop_animation()
	instal_proc_finish.visible = true
	instal_proc_load_icon.visible = false
	instal_proc_load_icon_space.visible = true


func _on_FileDialogInstall_pressed():
	Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
			self,
			"_on_install_path_selected",
			FileDialog.MODE_OPEN_DIR
			]).execute()


func _on_FileDialogOpenInstalled_pressed():
	Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
			self,
			"_on_open_installed_path_selected",
			FileDialog.MODE_OPEN_DIR
			]).execute()


func _on_install_path_selected(path: String):
	install_path.text = path


func _on_open_installed_path_selected(path: String):
	selected_installation_path.text = path
	refresh_open_installed_arguments(path)


func hide_installation_window(_cue: Cue = null):
	Tutorials.run_with_name(Tutorials.TUT1, true)
	visible = false


func show_installation_window(cue: Cue = null):
	# [ is_mandatory ]
	var is_mandatory: bool = cue.bool_at(0, true, false)
	clear_ui()
	visible = true
	if is_mandatory:
		main_options_exit.visible = false
	else:
		main_options_exit.visible = true


func show_installation_progress():
	if hide_on_back.empty():
		UIOrganizer.hide_show_node(main_options_ui, instal_proc_ui, 
				UI_CHANGE_TIME, UI_CHANGE_TIME)
	else:
		UIOrganizer.hide_show_node(_peek_hide_on_back(), instal_proc_ui, 
				UI_CHANGE_TIME, UI_CHANGE_TIME)
	
	hide_on_back.push_back(instal_proc_ui)


func set_install_step(cue: Cue):
	# [ text ]
	var text = cue.str_at(0, '')
	instal_proc_load_icon.start_animation()
	instal_proc_step.text = text


func _on_MainInstallServer_pressed():
	Cue.new(Consts.ROLE_DIALOGS, 'request_confirmation').args([
			MSG_BETA_FEATURE_CONTINUE, 
			self, 
			"_on_Confirmed_MainInstallServer_pressed"
	]).execute()


func _on_Confirmed_MainInstallServer_pressed():
	UIOrganizer.hide_show_node(main_options_ui, install_option_ui, UI_CHANGE_TIME, UI_CHANGE_TIME)
#	install_option_ui.visible = true
#	main_options_ui.visible = false
	hide_on_back.push_back(install_option_ui)


func _on_MainOpenInstallation_pressed():
	UIOrganizer.hide_show_node(main_options_ui, choose_installed_option_ui, UI_CHANGE_TIME, UI_CHANGE_TIME)
#	choose_installed_option_ui.visible = true
#	main_options_ui.visible = false
	hide_on_back.push_back(choose_installed_option_ui)


func _on_MainAddRemoteServer_pressed():
	UIOrganizer.hide_show_node(main_options_ui, remote_server_option_ui, UI_CHANGE_TIME, UI_CHANGE_TIME)
#	remote_server_option_ui.visible = true
#	main_options_ui.visible = false
	hide_on_back.push_back(remote_server_option_ui)


func _on_Back_pressed():
	if hide_on_back.empty():
		return
	
	UIOrganizer.hide_show_node(_peek_hide_on_back(), _peek_hide_on_back(1), UI_CHANGE_TIME, UI_CHANGE_TIME)
#	main_options_ui.visible = true
#	hide_on_back.visible = false
	hide_on_back.pop_back()


func _on_PythonInterface_output_received(text_line):
	if text_output_to_console:
		instal_proc_output.text += "\n" + text_line
		l.g(text_line, l.INFO)
	
	if stop_load_icon_if_no_output:
		instal_proc_load_icon_timer.start()


func _on_PythonInterface_last_line_replaced(text_line):
	if text_output_to_console:
		instal_proc_output.remove_line(instal_proc_output.get_line_count() - 1) 
		instal_proc_output.text += text_line
	
	if stop_load_icon_if_no_output:
		instal_proc_load_icon_timer.start()


func _on_FinishInstallation_pressed():
	hide_installation_window()


func _on_ResumeInstallation_pressed():
	if local_backend.repo == null:
		return
	
	# install may request the install to pause, causing the resume button to show 
	# and the load icon to hide, thus, showing the button and hiding the icon must 
	# come before calling install 
	set_pause_indicator(false)
	local_backend.repo.install()


func cue_pause_indicator(cue: Cue):
	set_pause_indicator(cue.bool_at(0, false))


func _on_AvailableServers_option_selected(_label_id, _index_id):
	refresh_new_install_arguments()
	refresh_versions()


func _peek_hide_on_back(deepth: int = 0, default = main_options_ui):
	var pos = hide_on_back.size() - 1 - deepth
	if pos >= 0:
		return hide_on_back[pos]
	else:
		return default


func get_full_installation_path(_cue: Cue = null) -> String:
	if local_backend.repo == null:
		l.g("Attemp to get full installation path in server_management_ui before" + 
				" specifying a repo")
		return ''
	
	if local_backend.repo.full_path.empty():
		l.g("Attemp to get full installation path in server_management_ui before" + 
				" specifying the path")
		return ''
	else:
		return local_backend.repo.full_path


func start_server(cue: Cue = null) -> PythonInterface:
	# By default, if activated through here the text won't be added to this scene console,
	# this is because said console will only be visible when installing/reinstalling, but
	# when doing so, that is done using the backend's method rather than this one
	if local_backend.repo == null:
		l.g("Attemp to run a local repo in server_management_ui before specifying the repo")
		return null
	
	
	text_output_to_console = cue.bool_at(0, false, false)
	return local_backend.repo.run()


func connect_server_output(cue: Cue):
	# [ object, method]
	var object = cue.get_at(0, null)
	var method = cue.str_at(1, '')
	if object == null or method.empty():
		return
	
	var error = Python.connect("output_received", object, method)
	l.error(error, l.CONNECTION_FAILED)


func connect_last_line_replaced(cue: Cue):
	# [ object, method]
	var object = cue.get_at(0, null)
	var method = cue.str_at(1, '')
	if object == null or method.empty():
		return
	
	var error = Python.connect("output_last_line_replaced", object, method)
	l.error(error, l.CONNECTION_FAILED)


func _on_global_save_cues_requested():
	if local_backend.repo == null:
		return
	
	if not local_backend.repo.full_path.empty():
		Director.add_global_save_cue(
				Consts.ROLE_SERVER_MANAGER, 
				"set_installation_info", 
				[
					get_full_installation_path(), 
					local_backend.repo.data.pc.gpu_type,
					local_backend.repo.extra_args
				],
				{ "backend": local_backend.repo.data.id}
		)


func _on_Language_option_selected(label_id, _index_id):
	UIOrganizer.set_locale(label_id)


func get_local_repository(_cue: Cue) -> LocalRepo:
	return local_backend.repo


func clear_ui():
	hide_on_back = []
	main_options_ui.visible = true
	install_option_ui.visible = false
	choose_installed_option_ui.visible = false
	remote_server_option_ui.visible = false
	instal_proc_ui.visible = false


func set_pause_indicator(show: bool):
	instal_proc_resume.visible = show
	instal_proc_step.visible = not show
	instal_proc_load_icon.visible = not show
	instal_proc_load_icon_space.visible = show
	instal_proc_step.rect_min_size.y = instal_proc_resume.rect_size.y
	instal_proc_load_icon_space.rect_min_size.y = instal_proc_load_icon.rect_min_size.y


func cue_icon_stop_if_no_output(cue: Cue):
	# [ stop: bool, time_seconds: int = 30 ]
	stop_load_icon_if_no_output = cue.bool_at(0, true)
	instal_proc_load_icon_timer.wait_time = cue.int_at(1, 30, false)
	if stop_load_icon_if_no_output:
		instal_proc_load_icon_timer.start()
	else:
		instal_proc_load_icon_timer.stop()
	
	if visible:
		instal_proc_load_icon.start_animation()


func cue_text_to_console(cue: Cue):
	# [ text_line ]
	var text_line = cue.str_at(0, '')
	instal_proc_output.text += text_line + "\n"
	


func _prepare_repo(repo: LocalRepo): #, signal_folder_changed: bool
	local_backend.repo = repo
	var api = DiffusionServer.instance_api(repo.data.api_gdscript)
	if api != null:
		api.refresh_paths()
	
	# DEPRECATED until release remove any commented code related to Ctrl + Shift + F installation_folder_changed
	
#	if signal_folder_changed:
#		emit_signal("installation_folder_changed", repo.full_path)


func _on_ConfirmationDialog_confirmed():
	set_pause_indicator(false)


func _on_ConfirmationDialog_popup_only_closed():
	hide_installation_window()


func _on_InstallationLoadingIconTimer_timeout():
	instal_proc_load_icon_timer.stop()
	instal_proc_load_icon.pause_animation()


func _on_ExitInstallerButton_pressed():
	hide_installation_window()


func _on_InstallPath_text_changed(_new_text):
	refresh_new_install_arguments()


func refresh_new_install_arguments():
	var server_id = available_servers.get_selected()
	var selected_gpu = available_gpu_install.get_selected()
	if server_id == null or selected_gpu == null:
		# This is to protect in case info is not yet loaded
		return
	
	var repo_data: RepoData = local_backend.servers.get(server_id, null)
	if repo_data == null:
		l.g("Repository id " + str(server_id) + " wasn't found in available servers")
		return
	
	var pc_data = PCData.new()
	set_gpu_in_pcdata(pc_data, selected_gpu)
	install_core_args.text = repo_data.get_start_args_custom(pc_data)


func _on_SelectedInstallationPath_text_changed(new_text):
	refresh_open_installed_arguments(new_text)


func refresh_open_installed_arguments(path: String):
	if path.strip_edges().empty():
		return
	
	var repo = get_repo_from_path(path)
	var args = ''
	if repo != null:
		var pc_data = PCData.new()
		set_gpu_in_pcdata(pc_data, available_gpu_open.get_selected())
		args = repo.data.get_start_args_custom(pc_data)
	
	selected_installation_core_args.text = args


func set_gpu_in_pcdata(pc_data: PCData, selected_gpu):
	match selected_gpu:
		AMD:
			pc_data.gpu_type = PCData.GPU.AMD
		NVIDIA:
			pc_data.gpu_type = PCData.GPU.NVIDIA


func _on_InstallAvailableGPU_option_selected(_label_id, _index_id):
	refresh_new_install_arguments()


func _on_OpenAvailableGPU_option_selected(_label_id, _index_id):
	refresh_open_installed_arguments(selected_installation_path.text)


func _on_OpenAvailableServers_option_selected(_label_id, _index_id):
	var server_id = available_servers_open.get_selected()
	var repo_data: RepoData = local_backend.servers.get(server_id, null)
	var args = ''
	if repo_data != null:
		var pc_data = PCData.new()
		set_gpu_in_pcdata(pc_data, available_gpu_open.get_selected())
		args = repo_data.get_start_args_custom(pc_data)
	
	selected_installation_core_args.text = args
