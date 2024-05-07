extends ModifierMode

class_name RegionPromptModifierMode

var layer_id: String = ''
var controller_role: String = Consts.ROLE_CONTROL_REGION_PROMPT
var active_regions: Array = []

func select_mode():
	if selected:
		return
	
	selected = true
	Cue.new(controller_role, "open_board").args([self]).execute()
	layer_id = Cue.new(controller_role, 'prepare_regions').args([layer_id]).execute()
	
	if data_cue != null:
		data_cue.clone().execute()


func deselect_mode():
	data_cue = Cue.new(controller_role, "get_data_cue").execute()
	active_image = Cue.new(controller_role, "get_active_image").execute()
	active_regions = Cue.new(controller_role, "get_active_regions").execute()
	Cue.new(controller_role, "deselect_tools").execute()
	selected = false
	if owner is Modifier:
		var image_data = ImageData.new("regional_prompting" + "_screenshot")
		image_data.load_image_object(active_image)
		owner._refresh_image_data_with(image_data)


func prepare_mode():
	pass


func apply_to_api(api):
	if selected:
		active_regions = Cue.new(controller_role, "get_active_regions").execute()
	
	
	if api.has_method("queue_regions_to_bake"):
		api.queue_regions_to_bake(active_regions)


func clear_board():
	Cue.new(controller_role, "clear").execute()


func _on_same_type_modifier_toggled():
	# If we decide to add the overlay and under lay, the code to update will be here
	pass


func get_active_image():
	if active_image != null:
		return active_image
	else:
		return null
