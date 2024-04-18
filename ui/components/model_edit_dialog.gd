extends WindowDialog


onready var model_details_viewer = $ModelDetailsViewer


var hide_model_selector


func _ready():
#	popup_centered_ratio(0.5)
#	var rect = get_global_rect()
	Roles.request_role(self, Consts.ROLE_MODEL_EDITOR)
#	model_details_viewer.connect("close_requested", self, "close")
	#show()


func close(_cue: Cue = null):
	hide()


func open(cue: Cue):
	# [ file_cluster ]
	# { hide_model_selector: bool = true }
	var file_cluster_thumbnail = cue.get_at(0, null)
	hide_model_selector = cue.bool_option("hide_model_selector", true)
	
	if file_cluster_thumbnail is FileClusterThumbnail:
		model_details_viewer.set_data(file_cluster_thumbnail.file_cluster)
		show()


func _on_ModelDetailsViewer_close_requested():
	close()


func _on_ModelEditDialog_visibility_changed():
	if hide_model_selector:
		if visible:
			Cue.new(Consts.ROLE_MODEL_SELECTOR, "quick_close").execute()
		else:
			Cue.new(Consts.ROLE_MODEL_SELECTOR, "open").execute()
