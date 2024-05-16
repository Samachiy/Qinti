extends ControlnetNoCanvasController


func _ready():
	# Configuring inherited varaibles
	cn_model_type = Consts.CN_TYPE_COLOR


func get_data_cue(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	if layer_name.empty():
		return null
	
	var cue = Cue.new(Consts.ROLE_CONTROL_COLOR, 'set_data_cue')
	return cue


func set_data_cue(_cue: Cue):
	clear()


func _fill_menu():
	pass # There's nothing to fill
