extends MarginContainer


onready var models_container = $Margin/HBoxContainer/DiffusionModels
onready var close_button = $Margin/MarginContainer/Close

var current_model: FileCluster = null
var previous_model: FileCluster = null
var clusters: Dictionary
var load_model_on_close: FileCluster = null # to only load model on close
var queued_model_load: FileCluster = null # in case server is no up
var server_is_ready: bool = false
var current_model_thumbnail: ModelThumbnail = null

func _ready():
	Roles.request_role(self, Consts.ROLE_MODEL_SELECTOR)
	var e = DiffusionServer.connect("server_ready", self, "_on_server_ready")
	l.error(e, l.CONNECTION_FAILED)
#	Roles.connect_role(
#			Consts.ROLE_SERVER_MANAGER, "installation_folder_changed", 
#			self, "_on_installation_folder_changed")
	var error = DiffusionServer.connect("paths_refreshed", self, "_on_paths_refreshed")
	l.error(error, l.CONNECTION_FAILED)
	error = DiffusionServer.connect("diffusion_models_refreshed", self, "_on_models_refreshed")
	l.error(error, l.CONNECTION_FAILED)
	close_button.modulate.a8 = Consts.TERMINATE_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(close_button, Consts.THEME_MODULATE_GROUP_STYLE)
	Tutorials.subscribe(self, Tutorials.TUT6)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUT6:
			var step = tutorial_seq.add_tr_named_step(Tutorials.TUT6_SELECTING, [])
			step.cue_in_run(Cue.new(Consts.ROLE_MODEL_SELECTOR, "open"))
			tutorial_seq.add_tr_named_step(Tutorials.TUT6_SEARCH, 
					[models_container.search_bar])
			tutorial_seq.add_tr_named_step(Tutorials.TUT6_NEW_MODELS, 
					[models_container.external_button])


#func _on_installation_folder_changed(_path: String):
#	refresh_models()


func _on_paths_refreshed():
	refresh_models()


func refresh_models():
	var path = DiffusionServer.api.get_checkpoints_dir()
	
	var dir: Directory = Directory.new()
	if not dir.dir_exists(path):
		l.g("Can't read installation folder info, folder doesn't exist")
		return
	
	clusters = get_file_clusters_at(path)
	models_container.clear()
	models_container.load_file_clusters(clusters, '')
	for node in models_container.get_items():
		if node is ModelThumbnail:
			node.connect("model_selected", self, "_on_model_selected")


# DEPRECATED function unless another api needs something like this
func filter_clusters(unfiltered_clusters: Dictionary):
	if DiffusionServer.diffusion_models == null:
		return unfiltered_clusters 
	
	var filtered_clusters = {}
	for model_key in DiffusionServer.diffusion_models:
		if model_key in unfiltered_clusters:
			filtered_clusters[model_key] = unfiltered_clusters[model_key]
	
	return filtered_clusters


func get_file_clusters_at(path: String) -> Dictionary:
	return Cue.new(Consts.ROLE_FILE_PICKER, "get_file_clusters").args([path]).execute()


func _on_server_ready():
	DiffusionServer.get_server_config(self, "_on_first_server_config_received")


func _on_first_server_config_received(server_config):
	if clusters.empty():
		refresh_models()
	server_is_ready = true
	var server_model = DiffusionServer.get_server_diffusion_model_from_config(server_config)
	server_model = DiffusionServer.api.get_checkpoints_dir().plus_file(server_model)
	var server_model_cluster =  clusters.get(server_model, null)
	Cue.new(Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP, "cue_cluster").args([
			server_model_cluster]).execute()
	if server_model_cluster == null:
		l.g("Problem getting the current diffusion model, checkpoint '" + 
				server_model + "' doesn't appear in models folder.")
	
	# if the user changed model before the server is up, the model is queued
	# so we load the queued model if that's the case
	if queued_model_load == null:
		if server_model_cluster == null:
			return
		current_model = server_model_cluster
		previous_model = server_model_cluster
		show_selected_model(current_model)
	else:
		previous_model = server_model_cluster
		set_diffusion_model(queued_model_load)


func show_selected_model(file_cluster: FileCluster):
	for model_thumbnail in models_container.get_items():
		if model_thumbnail.file_cluster.name == file_cluster.name:
			model_thumbnail.is_selected = true
			current_model_thumbnail = model_thumbnail
			break


func set_diffusion_model(model_file_cluster: FileCluster):
	previous_model = current_model
	current_model = model_file_cluster
	Cue.new(Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP, "start_animation").execute()
	DiffusionServer.set_server_diffusion_model(
			model_file_cluster.main_file.get_file(), 
			self, 
			"_on_set_diffusion_model_success",
			"_on_set_diffusion_model_failure")


func _on_set_diffusion_model_success(_result):
	load_model_on_close = null
	queued_model_load = null
	DiffusionServer.get_server_config(self, "_on_first_server_config_received")
	Cue.new(Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP, "cue_cluster").args([
			current_model]).execute()


func _on_set_diffusion_model_failure(response_code):
	current_model = previous_model
	load_model_on_close = null
	queued_model_load = null
	DiffusionServer.get_server_config(self, "_on_first_server_config_received")
	Cue.new(Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP, "stop_animation").execute()
	if not server_is_ready:
		queued_model_load = current_model
		l.g("Couldn't set diffusion model '" + current_model.name + 
				"'. Response code: " + str(response_code))


func close(_cue: Cue = null):
	if load_model_on_close is FileCluster:
		set_diffusion_model(load_model_on_close)
	
	visible = false


func quick_close(_cue: Cue = null):
	load_model_on_close = null
	visible = false


func open(_cue: Cue = null):
	models_container.clear_search()
	visible = true


func _on_DiffusionModels_refresh_requested():
	DiffusionServer.refresh_data(DiffusionAPI.REFRESH_MODELS)


func _on_models_refreshed(_success: bool):
	refresh_models()
	DiffusionServer.get_server_config(self, "_on_first_server_config_received")


func _on_model_selected(model_thumbnail: ModelThumbnail):
	if model_thumbnail == null:
		return
	
	if is_instance_valid(current_model_thumbnail) and current_model_thumbnail is ModelThumbnail:
		current_model_thumbnail.is_selected = false
	
	load_model_on_close = model_thumbnail.file_cluster
	current_model_thumbnail = model_thumbnail
	current_model_thumbnail.is_selected = true
	


func _on_Close_pressed():
	close()


func _on_DiffusionModels_external_path_requested():
	OS.set_clipboard(DiffusionServer.api.get_checkpoints_dir())
