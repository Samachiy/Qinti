extends WindowDialog


onready var styling_details_viewer = $StyleDetailsViewer


func _ready():
#	popup_centered_ratio(0.5)
#	var rect = get_global_rect()
	Roles.request_role(self, Consts.ROLE_STYLE_EDITOR)
	#styling_details_viewer.connect("close_requested", self, "close")
	#show()


func close(_cue: Cue = null):
	hide()


func open(cue: Cue):
	# [ styling_data ]
	var styling_data = cue.get_at(0, null)
	if styling_data is StylingData:
		styling_details_viewer.set_data(styling_data)
		show()


func _on_StyleDetailsViewer_close_requested():
	close()
