extends ModifierMode

const CONTROLLER_DATA = "controller"


var styling_data: StylingData = null
var controller_role = Consts.ROLE_CONTROL_STYLING
var prompt_cue: Cue = null
var is_hash_requested: bool = false


func select_mode():
	if selected:
		return
	selected = true
	Cue.new(controller_role, "open_board").args([self]).execute()
	if data_cue == null:
		Cue.new(controller_role, "set_base_data").args([styling_data]).execute()
	else:
		data_cue.clone().execute()


func deselect_mode():
	selected = false
	data_cue = Cue.new(controller_role, "get_data_cue").execute()
	prompt_cue = Cue.new(controller_role, "get_prompt_cue").execute()


func prepare_mode():
	if is_hash_requested:
		return
	
	styling_data.file_cluster.solve_hash(false)
	pass


func apply_to_api(_api):
	if selected:
		prompt_cue = Cue.new(controller_role, "get_prompt_cue").execute()
	elif prompt_cue == null:
		var dict: Array = [
			styling_data.get_positive_prompt(),
			styling_data.get_negative_prompt()
		]
		prompt_cue =  Cue.new(Consts.ROLE_API, "add_to_prompt").args(dict)
	
	prompt_cue.clone().execute()


func clear_board():
	Cue.new(controller_role, "clear").execute()


func get_model_hash():
	styling_data.file_cluster.get_hash()


func queue_hash_now():
	styling_data.file_cluster.solve_hash(true)


func get_mode_data():
	var data = {
		CONTROLLER_DATA: data_cue,
	}
	return data


func set_mode_data(data: Dictionary):
	data_cue = data.get(CONTROLLER_DATA, null)

