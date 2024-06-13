extends ModifierMode

const LAYER_ID = "layer"
const PARAMETERS = "param"
const CONTROLLER_DATA = "controller"
const ACTIVE_IMAGE = "active_img"

var layer_id: String = ''
var controller_role: String = Consts.ROLE_CONTROL_IMG2IMG
var img2img_dict = null
var undoredo_data: Canvas2DUndoQueue = null


func select_mode():
	if selected:
		return
	selected = true
	Cue.new(controller_role, "open_board").args([self]).execute()
	layer_id = Cue.new(controller_role, 'prepare_layer').args([layer_id]).execute()
	
	# There's no need to do special check with undoredo_data since those checks are already
	# taken care on the controller side (in base_controller.gd)
	undoredo_data = Cue.new(controller_role, "set_undoredo_data").args([undoredo_data]).execute()
	
	if data_cue == null:
		restore_image_data = image_data
		Cue.new(controller_role, "set_image").args(
				[image_data]).execute()
	else:
		data_cue.clone().execute()
	
	Cue.new(controller_role, "update_overlay_underlay").args([name, owner]).execute()


func deselect_mode(_is_mode_change: bool):
	Cue.new(controller_role, "pause_layer").execute()
	undoredo_data = Cue.new(controller_role, "get_undoredo_data").execute()
	data_cue = Cue.new(controller_role, "get_data_cue").execute()
	active_image = Cue.new(controller_role, "get_active_image").execute()
	img2img_dict = Cue.new(controller_role, "get_img2img_dict").args(
			[active_image, false]).execute()
	Cue.new(controller_role, "deselect_tools").execute()
	selected = false


func prepare_mode():
	pass


func clear_board():
	Cue.new(controller_role, "clear").execute()


func _on_same_type_modifier_toggled():
	Cue.new(controller_role, "update_overlay_underlay").args([name, owner]).execute()


func apply_to_api(api):
	if selected:
		active_image = Cue.new(controller_role, "get_active_image").execute()
		img2img_dict = Cue.new(controller_role, "get_img2img_dict").args(
				[active_image, false]).execute()
	
	if active_image == null:
		img2img_dict = Cue.new(controller_role, "get_img2img_dict").args(
				[image_data.image]).execute()
	elif img2img_dict == null:
		img2img_dict = Cue.new(controller_role, "get_img2img_dict").args(
				[active_image]).execute()
	
	if api.has_method("queue_img2img_to_bake"):
		api.queue_img2img_to_bake(img2img_dict)
 

func get_active_image():
	if active_image != null:
		return active_image
	elif image_data != null:
		return image_data.image
	else:
		return null


func get_mode_data():
	if selected:
		data_cue = Cue.new(controller_role, "get_data_cue").execute()
		active_image = Cue.new(controller_role, "get_active_image").execute()
		img2img_dict = Cue.new(controller_role, "get_img2img_dict").args(
				[active_image, false]).execute()
	
	var disassembled_data_cue = []
	if data_cue is Cue:
		disassembled_data_cue = data_cue.disassemble()
	var data = {
		LAYER_ID: layer_id,
		CONTROLLER_DATA: disassembled_data_cue,
		ACTIVE_IMAGE: ImageProcessor.image_to_base64(get_active_image()),
		PARAMETERS: img2img_dict
	}
	return data


func set_mode_data(data: Dictionary):
	layer_id = data.get(LAYER_ID, '')
	var disassembled_data_cue = data.get(CONTROLLER_DATA, [])
	data_cue = Cue.new('', '').assemble(disassembled_data_cue, false)
	var active_image_base64 = data.get(ACTIVE_IMAGE, '')
	if not active_image_base64.empty():
		active_image = ImageProcessor.png_base64_to_image(active_image_base64)
	else:
		l.g("Tried to load from file an empty image_bse64 string onto mode: " + name)
	img2img_dict = data.get(PARAMETERS, {})


func _on_deleted_modifier():
	if layer_id.empty():
		return
	
	Cue.new(controller_role, 'mark_skip_layer_save').args([layer_id, true]).execute()


func _on_undeleted_modifier():
	if layer_id.empty():
		return
	
	Cue.new(controller_role, 'mark_skip_layer_save').args([layer_id, false]).execute()


func _on_destroyed_modifier():
	if layer_id.empty():
		return
	
	Cue.new(controller_role, 'remove_layer').args([layer_id]).execute()
