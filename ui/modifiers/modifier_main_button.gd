extends TextureButton



func get_drag_data(_position: Vector2):
	if not owner is Modifier:
		l.g("Modifier main button doesn't belong to modifier, can't get drag data")
		return null
	
	var mydata: Modifier = owner
	var preview = TextureRect.new()
	preview.expand = true
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	preview.texture = mydata.image_data.texture
	preview.rect_size = rect_size
	preview.connect("tree_exiting", self, "_on_drag_preview_tree_exiting")
	set_drag_preview(preview)
	Cue.new(Consts.ROLE_GENERATION_INTERFACE, "set_on_top").args([preview]).execute()
	Cue.new(Consts.UI_DROP_GROUP, "enable_drop").execute()
	owner.visible = false
	return mydata


func _on_drag_preview_tree_exiting():
	owner.visible = true
