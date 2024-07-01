extends VBoxContainer

onready var recent_container = $TabContainer/RECENT
onready var styling_container = $TabContainer/STYLING
onready var lora_container = $TabContainer/STYLING/Loras
onready var lycoris_container = $TabContainer/STYLING/Lycoris
onready var ti_container = $TabContainer/STYLING/TextualInversion
onready var all_container = $TabContainer/STYLING/All
onready var tab_container = $TabContainer
onready var refresh_all_timer = $RefreshAllTimer

var last_recent_thumbnail: RecentThumbnail = null
var lora_thread: Thread
var lycoris_thread: Thread
var ti_thread: Thread
var refreshed_containers: Dictionary = {}
var save_recent_img_amount: int = 20

var lora_thread_running: bool = false
var lycoris_thread_running: bool = false
var ti_thread_running: bool = false

signal file_clusters_refreshed

func _ready():
	#recent_container.container.load_images_from_folder("res://Placeholders/") # for test purposes
	Roles.request_role(self, Consts.ROLE_TOOLBOX)
	var error = DiffusionServer.connect("paths_refreshed", self, "_on_paths_refreshed")
	yield(get_tree().current_scene, "ready")
	l.error(error, l.CONNECTION_FAILED)
	
	Tutorials.subscribe(self, Tutorials.TUT2)
	Tutorials.subscribe(self, Tutorials.TUT3)
	Tutorials.subscribe(self, Tutorials.TUT5)
	Tutorials.subscribe(self, Tutorials.TUT8)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUT2:
			select_tab_control(recent_container)
			tutorial_seq.add_tr_named_step(Tutorials.TUT2_SAVE_GENERATION, 
					[recent_container])
			tutorial_seq.add_tr_named_step(Tutorials.TUT2_SAVE_IMAGE_VIEWER, 
					[recent_container])
		Tutorials.TUT3:
			select_tab_control(recent_container)
		Tutorials.TUT5:
			select_tab_control(styling_container)
			tutorial_seq.add_tr_named_step(Tutorials.TUT5_OPENING, [styling_container])
			var current_type = lora_container
			for child in styling_container.get_children():
				if child.visible:
					current_type = child
					break
			
			current_type.visible = true
			tutorial_seq.add_tr_named_step(Tutorials.TUT5_NAVIGATION, 
					[current_type.styles_types])
			tutorial_seq.add_tr_named_step(Tutorials.TUT5_NAVIGATION, 
					[current_type.search_bar])
			tutorial_seq.add_tr_named_step(Tutorials.TUT5_NEW_MODELS, 
					[current_type.external_button])
		Tutorials.TUT8:
			select_tab_control(recent_container)
			tutorial_seq.add_tr_named_step(Tutorials.TUT8_SAVING_RECENT, [recent_container])


func select_tab_control(control: Control):
	var index = 0
	for i in range(0, tab_container.get_child_count()):
		if tab_container.get_child(i) == control:
			index = i 
			break
	
	tab_container.current_tab = index


func _on_paths_refreshed():
	add_LORAs()
	add_LyCORIS()
	add_TIs()


func add_recent_png_images(cue: Cue):
	# [image1: PoolByteArray, image2: PoolByteArray, image3: PoolByteArray, ...]
	# { 'name' = image_name }
	var images = []
	var image_data
	var image_name = cue.str_option("name", 'generated_image')
	for raw_image in cue._arguments:
		image_data = ImageData.new(image_name).load_data(raw_image, ImageData.PNG)
		images.append(image_data)
	
	return _add_recent_images(images)


func add_recent_data_images(cue: Cue):
	# [image1: ImageData, image2: ImageData, image3: ImageData, ...]
	return _add_recent_images(cue._arguments)


func _add_recent_images(images_data: Array, refresh_order: bool = true) -> RecentThumbnail:
	# [image1: PoolByteArray, image2: PoolByteArray, image3: PoolByteArray, ...]
	var thumbnail = recent_container.create_thumbnail()
	thumbnail.set_batch_image_data(images_data)
	if refresh_order:
		recent_container.refresh_order()
	last_recent_thumbnail = thumbnail
	return thumbnail


func refresh_recent_images_order(_cue: Cue = null):
	recent_container.refresh_order()


func add_LORAs(thread: bool = true):
	var path = DiffusionServer.api.get_lora_dir()
	if thread:
		if lora_thread is Thread:
			if lora_thread.is_alive():
				l.g("lora_thread alive")
				return
			elif lora_thread.is_active():
				l.g("lora_thread is_active")
				lora_thread.wait_to_finish()
		
		lora_thread = thread_get_file_clusters_at(
				path, 
				"_thread_add_LORAs", 
				lora_container.get_cleared_clusters()
		)
	else:
		var clusters = get_file_clusters_at(path, lora_container.get_cleared_clusters())
		_set_clusters(lora_container, clusters, StylingData.LORA_FORMAT)


func add_LyCORIS(thread: bool = true):
	var path = DiffusionServer.api.get_lycoris_dir()
	if thread:
		if lycoris_thread is Thread:
			if lycoris_thread.is_alive():
				l.g("lycoris_thread alive")
				return
			elif lycoris_thread.is_active():
				l.g("lycoris_thread is_active")
				lycoris_thread.wait_to_finish()
		
		lycoris_thread = thread_get_file_clusters_at(
				path, 
				"_thread_add_LyCORIS", 
				lycoris_container.get_cleared_clusters()
		)
	else:
		var clusters = get_file_clusters_at(path, lycoris_container.get_cleared_clusters())
		_set_clusters(lycoris_container, clusters, StylingData.LYCORIS_FORMAT)


func add_TIs(thread: bool = true):
	var path = DiffusionServer.api.get_textual_inversion_dir()
	if thread:
		if ti_thread is Thread:
			if ti_thread.is_alive():
				l.g("ti_thread alive")
				return
			elif ti_thread.is_active():
				l.g("ti_thread is_active")
				ti_thread.wait_to_finish()
		
		ti_thread = thread_get_file_clusters_at(
				path, 
				"_thread_add_TIs", 
				ti_container.get_cleared_clusters()
		)
	else:
		var clusters = get_file_clusters_at(path, ti_container.get_cleared_clusters())
		_set_clusters(ti_container, clusters, StylingData.TI_FORMAT)


func get_style_thumbnails_by_q_hash(cue: Cue):
	# [ q_hash ]
	var q_hash = cue.get_at(0, '')
	return all_container.container.get_thumbnail_q_hash(q_hash)


func add_all_clusters():
# warning-ignore:return_value_discarded
	refreshed_containers.erase(all_container)
	if refreshed_containers.size() == 0:
		return
	else:
		refreshed_containers.clear()
		pass
	
	all_container.clear()
	_set_clusters(all_container, 
			lora_container.get_clusters(), StylingData.LORA_FORMAT, false, false)
	_set_clusters(all_container, 
			lycoris_container.get_clusters(), StylingData.LYCORIS_FORMAT, false, false)
	_set_clusters(all_container, 
			ti_container.get_clusters(), StylingData.TI_FORMAT, false, false)


func _thread_add_LORAs(clusters: Dictionary):
	_set_clusters(lora_container, clusters, StylingData.LORA_FORMAT)
	_dispose_thread(lora_thread)


func _thread_add_LyCORIS(clusters: Dictionary):
	_set_clusters(lycoris_container, clusters, StylingData.LYCORIS_FORMAT)
	_dispose_thread(lycoris_thread)


func _thread_add_TIs(clusters: Dictionary):
	_set_clusters(ti_container, clusters, StylingData.TI_FORMAT)
	_dispose_thread(ti_thread)


func _set_clusters(container: VFlowClusters, clusters: Dictionary, styling_format: String, 
signal_refresh: bool = true, clear_container_first: bool = true):
	if clear_container_first:
		# We yield because, when we get the clusters, those will refresh
		# their image data on a thread
		# When image data is refreshed, is will call _on_Label_resized()
		# which holds a yield "idle_frame", if we clear it before that
		# yield "idle_frame" finishes, we will get an error, so we wait an
		# idle frame before clearing
		yield(get_tree(), "idle_frame")
		container.clear()
	
	container.load_file_clusters(clusters, styling_format)
	refreshed_containers[container] = true
	if signal_refresh:
		emit_signal("file_clusters_refreshed")


func _dispose_thread(thread: Thread):
	if thread is Thread and thread.is_active():
		thread.wait_to_finish()
		thread = null
	


func get_file_clusters_at(path: String, clusters: Dictionary) -> Dictionary:
	return Cue.new(Consts.ROLE_FILE_PICKER, "get_file_clusters").args([path]).opts({
			Consts.FILE_CLUSTERS: clusters
	}).execute()


func thread_get_file_clusters_at(path: String, receiving_method: String, 
clusters: Dictionary) -> Thread:
	return Cue.new(Consts.ROLE_FILE_PICKER, "thread_get_file_clusters").args(
			[path, self, receiving_method]
	).opts({
			Consts.FILE_CLUSTERS: clusters
	}).execute()


func _on_Loras_refresh_requested():
	add_LORAs()


func _on_Lycoris_refresh_requested():
	add_LyCORIS()


func _on_TextualInversion_refresh_requested():
	add_TIs()


func get_last_recent_thumbnail(_cue: Cue = null):
	return last_recent_thumbnail


func get_recent_thumbnail_number(_cue: Cue = null):
	return recent_container.container.thumbnails_children.size()


func _on_Loras_external_path_requested():
	OS.set_clipboard(DiffusionServer.api.get_lora_dir())


func _on_Lycoris_external_path_requested():
	OS.set_clipboard(DiffusionServer.api.get_lycoris_dir())


func _on_TextualInversion_external_path_requested():
	OS.set_clipboard(DiffusionServer.api.get_textual_inversion_dir())


func _on_RefreshAllTimer_timeout():
	refresh_all_timer.stop()
	add_all_clusters()


func _on_All_container_selected():
	if all_container == null:
		return
	
	if all_container.visible:
		add_all_clusters()


func _on_Toolbox_file_clusters_refreshed():
	refresh_all_timer.start()


func set_recent_img_save_amount(cue: Cue):
	# [ amount ]
	save_recent_img_amount = cue.int_at(0, save_recent_img_amount)


func _save_cues(_is_file_save):
	var images_data = []
	var thumbnails = recent_container.container.get_thumnails(save_recent_img_amount)
	for thumbnail in thumbnails:
		if thumbnail is RecentThumbnail:
			images_data.append(thumbnail.get_base64_images())
	
	Director.add_save_cue(
			Consts.SAVE, 
			Consts.ROLE_TOOLBOX, 
			"load_recent_images_data", 
			images_data)


func load_recent_images_data(cue: Cue):
	# [ image_base64_array1, image_base64_array2, ...]
	# image_base64_array = [ [image_name1, image_base64_1], [image_name2, image_base64_2], ...]
	recent_container.clear()
	var images_data 
	var image_base64: String = ''
	var image_name: String  = ''
	var aux: ImageData
	var entry
	for i in range(cue._arguments.size()):
		entry = cue._arguments[-i - 1] # We iterate in reverse
		images_data = []
		for data in entry:
			image_name = data[0]
			image_base64 = data[1]
			aux = ImageData.new(image_name)
			aux.load_base64(image_base64)
			images_data.append(aux)
		
		if not images_data.empty():
			# If there's demand to also restore gen layer contents, then it would go here
# warning-ignore:return_value_discarded
			_add_recent_images(images_data, false)
	
	recent_container.refresh_order()
