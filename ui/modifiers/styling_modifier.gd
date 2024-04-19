extends ModifierMode


var styling_data: StylingData = null
var controller_role = Consts.ROLE_CONTROL_STYLING
var prompt_cue: Cue = null


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

