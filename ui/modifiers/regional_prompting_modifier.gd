extends ModifierMode

class_name RegionPromptModifierMode

var layer_id: String = ''
var controller_role: String = Consts.ROLE_CONTROL_REGION_PROMPT
var undoredo_data: Canvas2DUndoQueue = null

func select_mode():
	if selected:
		return
	
	selected = true
	Cue.new(controller_role, "open_board").args([self]).execute()
	layer_id = Cue.new(controller_role, 'prepare_regions').args([layer_id]).execute()


func deselect_mode():
	selected = false


func prepare_mode():
	pass


func apply_to_api(_api):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'apply_to_api' has not been overriden yet on modifier mode: " + 
	name)


func clear_board():
	Cue.new(controller_role, "clear").execute()


func _on_same_type_modifier_toggled():
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function '_on_same_type_modifier_toggled' has not been overriden yet " + 
			"on modifier mode: " + name)


func get_active_image():
	# This function will be called more times on it's lifespan, program it accordingly
	# This function has to return an ImageData object
	l.g("The function 'get_active_image' has not been overriden yet on modifier mode: " + 
	name)
