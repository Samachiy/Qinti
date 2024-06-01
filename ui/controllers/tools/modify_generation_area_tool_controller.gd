extends ToolController

const SNAP_SIZE = 8
const CUSTOM_PROPORTIONS_KEY = "CUSTOM"

onready var width = $Width
onready var height = $Height
onready var denoising_strenght = $DenoisingStrenght
onready var outpaint_label = $OutpaintLabel
onready var use_modifiers = $Options/UseModifiers
onready var available_proportions = $Proportions
onready var outpaint_button = $Outpaint

enum undoredo_types{
	NONE,
	MOVE,
	EXPAND,
}

# proportions should always be lanscape mode here
var proportions: Dictionary = {
	CUSTOM_PROPORTIONS_KEY: Vector2.ZERO,
	"512 x 512": Vector2(512, 512),
	"768 x 768": Vector2(768, 768),
	"1024 x 1024": Vector2(1024, 1024),
	"16:9 512 x 288": Vector2(512, 288),
	"16:9 768 x 432": Vector2(768, 432),
	"16:9 1024 x 576": Vector2(1024, 576),
	"16:10 512 x 320": Vector2(512, 320),
	"16:10 768 x 480": Vector2(768, 480),
	"16:10 1024 x 640": Vector2(1024, 640),
}
var proportions_inverse: Dictionary = {
	CUSTOM_PROPORTIONS_KEY: CUSTOM_PROPORTIONS_KEY,
	Vector2(512, 512): "512 x 512",
	Vector2(768, 768): "768 x 768",
	Vector2(1024, 1024): "1024 x 1024",
	Vector2(512, 288): "16:9 512 x 288",
	Vector2(768, 432): "16:9 768 x 432",
	Vector2(1024, 576): "16:9 1024 x 576",
	Vector2(512, 320): "16:10 512 x 320",
	Vector2(768, 480): "16:10 768 x 480",
	Vector2(1024, 640): "16:10 1024 x 640",
}

var active_button = null
var generation_area = null
var outpaint_material = preload("res://ui/shaders/empty_area_mask_material.tres")
var ongoing_action: Canvas2DUndoAction = null
var undoredo_type = undoredo_types.NONE
var is_proportion_locked: bool = false
var snap: bool = true
var movement_cache: Vector2 = Vector2.ZERO # intended for snapping
var is_ready: bool = false


func _ready():
#	Director.connect_load_ready(self, "_on_ui_load_ready")
	yield(get_tree().current_scene, "ready")
	_on_ui_load_ready(false)
	
	# Adding proportions:
	for proportion in proportions.keys():
		available_proportions.add_tr_labeled_item(proportion)
	
	is_ready = true
	_detect_proportion()
	focus_gen_area()
	select_tool()
	var ds = DiffusionServer
	ds.connect_feature(ds.FEATURE_INPAINT_OUTPAINT, self, "_on_inpaint_outpaint_feature_toggled")


func _on_inpaint_outpaint_feature_toggled(enabled: bool):
	var menu_bar = Roles.get_node_by_role(Consts.ROLE_MENU_BAR)
	var is_advanced_ui
	if menu_bar is Control:
		is_advanced_ui = bool(menu_bar.get(Consts.UI_ADVANCED_GROUP))
	
	outpaint_button.visible = enabled
	if enabled:
		outpaint_label.add_to_group(Consts.UI_ADVANCED_GROUP)
		use_modifiers.add_to_group(Consts.UI_ADVANCED_GROUP)
		outpaint_label.visible = is_advanced_ui
		use_modifiers.visible = is_advanced_ui
	else:
		outpaint_label.remove_from_group(Consts.UI_ADVANCED_GROUP)
		use_modifiers.remove_from_group(Consts.UI_ADVANCED_GROUP)
		outpaint_label.visible = false
		use_modifiers.visible = false


func _detect_proportion():
	if not is_ready:
		return
	
	var prop = Vector2(width.get_value(), height.get_value())
	var prop_label: String = proportions_inverse.get(prop, '')
	if prop_label.empty():
		prop_label = proportions_inverse.get(Vector2(prop.y, prop.x), '')
	
	if prop_label.empty():
		available_proportions.select_by_label(CUSTOM_PROPORTIONS_KEY, true, false)
	else:
		available_proportions.select_by_label(prop_label, true, false)


func focus_gen_area():
	canvas.fit_to_rect2(generation_area.limits)
	canvas.display_area = generation_area.limits


func reload_description(_cue: Cue = null):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "add").opts({
		Consts.UI_CONTROL_LEFT_CLICK: Consts.HELP_DESC_MOVE_AREA,
	}).execute()


func _on_ui_load_ready(_is_loading_from_file):
	_update_shadow_areas()


func select_tool():
	if not button.pressed:
		button.pressed = true
	visible = true
	active_button = null
	generation_area.show_interactables()
	generation_area.transform_frame.visible = true
	generation_area.restore_pivot()
	generation_area.set_scale_on_expand(false)
	generation_area.set_lock_proportions(is_proportion_locked)
	_on_generation_area_proportions_changed(generation_area.limits)


func deselect_tool():
	visible = false
	active_button = null
	generation_area.hide_interactables()
	generation_area.set_scale_on_expand(false)


func _on_canvas_connected(canvas_node: Node):
	._on_canvas_connected(canvas_node)
# warning-ignore:return_value_discarded
	canvas_node.connect("layer_transform_button_pressed", self, 
			"_on_layer_transform_button_pressed")
	generation_area = canvas_node.generation_area
	generation_area.connect("proportions_changed", self, 
			"_on_generation_area_proportions_changed")
	generation_area.hide_interactables()
	
	var size = Vector2(512, 512)
	var rect2 = Rect2(- size / 2, size)
	generation_area.refresh_size_with(rect2)
	canvas.display_area = rect2


func _on_layer_transform_button_pressed(button):
	active_button = button
	active_button.active = true


func button_released(_event: InputEventMouseButton):
	if active_button != null:
		var aux = active_button
		active_button.active = false
		active_button = null
		aux.snap(SNAP_SIZE) 
	
	add_redo_action()
	undoredo_type = undoredo_types.NONE
	ongoing_action = null


func left_click(_event: InputEventMouseButton):
	if snap:
		generation_area.snap(SNAP_SIZE)
	
	return true


func left_click_drag(event: InputEventMouseMotion):
	if active_button == null:
		undoredo_type = undoredo_types.MOVE
		movement_cache += canvas.convert_movement(event.relative) 
		var move_amount
		var aux: Vector2 = Vector2.ZERO
		if snap:
			aux.x = fmod(movement_cache.x, SNAP_SIZE)
			aux.y = fmod(movement_cache.y, SNAP_SIZE)
			move_amount = movement_cache - aux
			movement_cache = aux
			generation_area.move_layer_by(move_amount)
		else:
			move_amount = movement_cache
			movement_cache = Vector2.ZERO
			generation_area.move_layer_by(move_amount)
	else:
		undoredo_type = undoredo_types.EXPAND
		active_button.move_by(
				canvas.convert_position_change(event.relative),
				true,
				SNAP_SIZE)
	
	add_undo_action()
	return true


func add_undo_action():
	if ongoing_action != null:
		return
	
	ongoing_action = canvas.undoredo_queue.add(generation_area)
	match undoredo_type:
		undoredo_types.MOVE:
			ongoing_action.add_undo_cue(Cue.new("", "cue_set_limits").args([
					generation_area.limits]))
		undoredo_types.EXPAND:
			ongoing_action.add_undo_cue(Cue.new("", "cue_expand_limits").args([
					generation_area.limits, false]))
		undoredo_types.NONE:
			l.g("Can't add redo action, no undoredo type specified at: " + str(filename))


func add_redo_action():
	if ongoing_action == null:
		return
	
	match undoredo_type:
		undoredo_types.MOVE:
			ongoing_action.add_redo_cue(Cue.new("", "cue_set_limits").args([
					generation_area.limits]))
		undoredo_types.EXPAND:
			ongoing_action.add_redo_cue(Cue.new("", "cue_expand_limits").args([
					generation_area.limits, false]))
		undoredo_types.NONE:
			l.g("Can't add redo action, no undoredo type specified at: " + str(filename))


func _on_generation_area_proportions_changed(rect2: Rect2):
	if rect2 == null:
		return
	
	width.set_value(rect2.size.x, false) # false, the value_changed signal won't be emitted
	height.set_value(rect2.size.y, false) # false, the value_changed signal won't be emitted
	_update_shadow_areas()
	_detect_proportion()


func _on_Height_value_changed(value):
	if generation_area == null: 
		return
	
	var rect2: Rect2 = generation_area.limits
	if is_proportion_locked:
		rect2.size.x *= value / rect2.size.y # scale according to proportion
		width.set_value(rect2.size.x, false) # false, the value_changed signal won't be emitted
	
	rect2.size.y = value
	generation_area.expand_limits(rect2, generation_area.get_scale_on_expand())
	_detect_proportion()


func _on_Width_value_changed(value):
	if generation_area == null: 
		return
	
	var rect2: Rect2 = generation_area.limits
	if is_proportion_locked:
		rect2.size.y *= value / rect2.size.x # scale according to proportion
		height.set_value(rect2.size.y, false) # false, the value_changed signal won't be emitted
	
	rect2.size.x = value
	generation_area.expand_limits(rect2, generation_area.get_scale_on_expand())
	_detect_proportion()


func get_width():
	if generation_area == null: 
		return 0
	else: 
		return width.get_value()


func get_height():
	if generation_area == null: 
		return 0
	else:
		return height.get_value()


func _update_shadow_areas():
	if generation_area == null:
		return
	
	var size = generation_area.limits.size
	Cue.new(Consts.UI_CANVAS_WITH_SHADOW_AREA, "set_shadow_area_cue").args([size]).execute()


func outpaint():
#	var mask: Image = canvas.current_layer.get_visible_mask()
	var size = generation_area.limits.size
	var image: Image = generation_area.get_contained_image()
	var base_image: Image = Image.new()
	base_image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	#base_image.blend_rect(image, Rect2(Vector2.ZERO, image.get_size()), Vector2.ZERO)
	ImageProcessor.blend_images(base_image, image)
	ImageProcessor.process_image(base_image, outpaint_material, self, "_on_mask_generated", [image])


func _on_mask_generated(mask: Image, bind_input_image: Image):
	if mask == null:
		return
	
	var config = {
#		Consts.I_DENOISING_STRENGTH: denoising_strenght.get_value(),
		Consts.I2I_INPAINT_FULL_RES: true,
	}
	Cue.new(Consts.ROLE_API, "clear").execute()
	DiffusionServer.api.queue_mask_to_bake(mask, bind_input_image, DiffusionAPI.MASK_MODE_OUTPAINT)
	
	Cue.new(Consts.ROLE_PROMPTING_AREA, "add_prompt_and_seed_to_api").execute()
	Cue.new(Consts.ROLE_CANVAS, "apply_parameters_to_api").execute()
	
	if use_modifiers.pressed:
		Cue.new(Consts.ROLE_GENERATION_INTERFACE, "apply_modifiers_to_api").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_img2img").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_mask").execute()
	Cue.new(Consts.ROLE_API, "bake_pending_controlnets").execute()
	Cue.new(Consts.ROLE_API, "cue_apply_parameters").opts(config).execute()
#	Cue.new(Consts.ROLE_API, "bake_pending_regional_prompts").execute()
	
	var prompting_area = Roles.get_node_by_role(Consts.ROLE_PROMPTING_AREA)
	if prompting_area is Object:
		DiffusionServer.generate(prompting_area, "_on_image_generated")
	else:
		l.g("Can't outpaint, there's no node with the role ROLE_PROMPTING_AREA")


func _on_AIProcessButton_pressed():
	outpaint()


func _on_LockProportion_toggled(button_pressed):
	is_proportion_locked = button_pressed
	generation_area.set_lock_proportions(is_proportion_locked)


func _on_SnapToGrid_toggled(button_pressed):
	snap = button_pressed


func _on_Proportions_option_selected(label_id, _index_id):
	if label_id == CUSTOM_PROPORTIONS_KEY:
		return
	
	var vector: Vector2 = proportions.get(label_id)
	if width.get_value() >= height.get_value():
		safe_set_dimensions(vector)
	else:
		safe_set_dimensions(Vector2(vector.y, vector.x))


func _on_InverseProportion_pressed():
	var vector = Vector2(height.get_value(), width.get_value())
	safe_set_dimensions(vector)


func safe_set_dimensions(size: Vector2):
	# Sets both the frame dimensions as well as the sliders, proven to not
	# cause anything unneeded 
	var aux = is_proportion_locked
	is_proportion_locked = false
	_on_Width_value_changed(size.x)
	_on_Height_value_changed(size.y)
	is_proportion_locked = aux
	width.set_value(size.x)
	height.set_value(size.y)


func _on_FocusGenerationArea_pressed():
	focus_gen_area()
