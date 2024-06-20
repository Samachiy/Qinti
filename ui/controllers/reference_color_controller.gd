extends ControlnetNoCanvasController


func _ready():
	# Configuring inherited varaibles
	cn_model_type = Consts.CN_TYPE_COLOR
	Tutorials.subscribe(self, Tutorials.TUTM11)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM11:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM11_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_CONTROLNET_WEIGHT, 
					[cn_config.weight])


func get_data_cue(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	if layer_name.empty():
		return null
	
	var cue = Cue.new(Consts.ROLE_CONTROL_COLOR, 'set_data_cue')
	return cue


func set_data_cue(_cue: Cue):
	clear()


func _fill_menu():
	canvas.menu.add_tr_labeled_item(Consts.MENU_SAVE_IMAGE)
	canvas.menu.add_tr_labeled_item(Consts.MENU_SAVE_IMAGE_AS)


func _on_Menu_option_selected(label_id, _index_id):
	match label_id:
		Consts.MENU_SAVE_CANVAS:
			var path = Cue.new(Consts.ROLE_FILE_PICKER, "get_default_save_path").execute()
			_on_canvas_save_path_selected(path, false)
		Consts.MENU_SAVE_CANVAS_AS:
			Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
					self,
					"_on_canvas_save_path_selected",
					FileDialog.MODE_SAVE_FILE
				]).opts({
					tr("SUPPORTED_SAVE_IMAGE_FORMAT"): "*.png" # donetr
				}).execute()


func _on_canvas_save_path_selected(path: String, overwrite: bool = true):
	ImageProcessor.save_image(canvas.get_canvas_image(), path, "canvas_image", true, overwrite)
