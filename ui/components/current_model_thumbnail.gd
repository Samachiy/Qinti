extends FileClusterThumbnail

class_name CurrentModelThumbnail

const MODEL_TR = "MODEL"

var model_name: String = ''

func _ready():
	add_to_group(Consts.UI_CURRENT_MODEL_THUMBNAIL_GROUP)
	var error = UIOrganizer.connect("locale_changed", self, "update_label")
	l.error(error, l.CONNECTION_FAILED)
	update_label()


func set_label(text: String):
	model_name = text.strip_edges()
	update_label()


func update_label(_locale = null):
	label.text = tr(MODEL_TR) + ": " + model_name # donetr
	label.text_label.align = label.text_label.ALIGN_CENTER


func cue_cluster(cue: Cue):
	# [file_cluster: FileCLuster ]
	var cluster = cue.get_at(0, null)
	if cluster != null:
		set_cluster(cluster)
		file_cluster.solve_hash(false)
		set_label(file_cluster.name)
		stop_animation()


func queue_hash_now(_cue: Cue = null):
	if file_cluster is FileCluster:
		file_cluster.solve_hash(true)


func start_animation(_cue: Cue = null):
	label.start_animation()


func stop_animation(_cue: Cue = null):
	label.stop_animation()


func _on_pressed():
	Cue.new(Consts.ROLE_MODEL_SELECTOR, "open").execute()


func _fill_menu():
	menu.add_tr_labeled_item(Consts.MENU_EDIT)


func _on_Menu_option_pressed(label_id, _index_id):
	match label_id:
		Consts.MENU_EDIT:
			Cue.new(Consts.ROLE_MODEL_EDITOR, "open").args([file_cluster]).execute()


func _on_Label_resized():
	yield(get_tree(), "idle_frame")
	
	label.rect_position.x = 0
	label.rect_size.x = rect_size.x
	label_bg.color.a8 = 200
	label.text_label.autowrap = false
	label.text_label.align = label.text_label.VALIGN_CENTER
	label.text_label.valign = label.text_label.VALIGN_CENTER
	label.text_label.clip_text = false
	
