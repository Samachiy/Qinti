extends ControlnetController


func _ready():
	# Configuring inherited varaibles
	cn_model_type = Consts.CN_TYPE_REFERENCE


func get_data_cue(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	if layer_name.empty():
		return null
	
	var cue = Cue.new(Consts.ROLE_CONTROL_IMG2IMG, 'set_data_cue')
	
	cue.args([
		canvas.display_area,
		layer_name,
		])
	
	return cue


func set_data_cue(cue: Cue):
	clear()
	var display_area = cue.get_at(0, Rect2(Vector2.ZERO, Vector2(512, 512)))
	var layer_name_ = cue.get_at(1, '')
	prepare_layer(Cue.new('', '').args([layer_name_]))
	if display_area is Rect2:
		canvas.display_area = display_area
		canvas.fit_to_rect2(display_area)
