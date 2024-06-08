extends Controller

class_name ControlnetController

const SCROLL_SCALE_AMOUNT = 20
const DISABLE_PREPROCESSOR_KEYWORD = "None"

onready var cn_config = $Container/Configs/ControlNetConfigs
onready var scroll = $Container
onready var top_gradient = $TopGradient
onready var bottom_gradient = $BottomGradient

var layer_name = ''
#var layer2d: Layer2D = null
var selected_preprocessor: String = ''
var original_image_data = null
var preprocessor_material = null
var texture_material = null
var overlay_underlay_material = null
var cn_model_type: String = ''


func _ready():
	var error = connect("canvas_connected", self, "prepare_canvas")
	l.error(error)
	
	# Adding the scroll indicators
	if scroll is ScrollContainer and top_gradient != null and bottom_gradient != null:
		var gradient_group = Consts.THEME_MODULATE_GROUP_STYLE
		UIOrganizer.add_to_theme_by_modulate_group(top_gradient, gradient_group)
		UIOrganizer.add_to_theme_by_modulate_group(bottom_gradient, gradient_group)
		scroll.get_v_scrollbar().connect("changed", self, "_on_scroll_changed")


func prepare_canvas(canvas: Control):
	canvas.add_to_group(Consts.UI_CANVAS_WITH_SHADOW_AREA)
	if canvas is Canvas2D:
		canvas.preview.set_preview_dimensions(canvas.PREVIEW_SIZE, canvas.PREVIEW_MARGIN)


func prepare_layer(cue: Cue):
	# [layer_name: String]
	canvas._on_resized()
	var layer_id = cue.get_at(0, '')
	var layer = canvas.select_layer(layer_id)
	if layer == null:
		layer_id = canvas.add_layer(layer_id)
		layer = canvas.select_layer(layer_id)
	
	layer.visible = true
	layer_name = layer_id
	#layer2d = layer
	return layer_id


func mark_skip_layer_save(cue: Cue):
	# [layer_name: String, skip_save: bool]
	var layer_name = cue.str_at(0, '')
	var skip_save = cue.bool_at(1, false)
	canvas.mark_layer_skip_save_as(layer_name, skip_save)


func pause_layer(_cue: Cue = null):
	l.p("Paused controller" + name)
	var layer = canvas.select_layer(layer_name)
	if layer != null:
		layer.consolidate()
		layer.visible = false


func consolidate_layer(_cue: Cue = null):
	var layer = canvas.select_layer(layer_name)
	if layer != null:
		layer.consolidate()


func reset_layer():
	var layer = canvas.select_layer(layer_name)
	if layer != null:
		layer.clear_image()
		layer.clear_mask()


func update_overlay_underlay(cue: Cue):
	# [target_mode: String, modifier: Modifier]
	# target mode is the type of modifier
	var target_mode = cue.str_at(0, '')
	var modifier = cue.get_at(1, null)
	Cue.new(Consts.ROLE_MODIFIERS_AREA, "update_canvas_overlay_underlay").args([
		canvas,
		target_mode,
		modifier, 
		overlay_underlay_material
	]).execute()
	Cue.new(Consts.ROLE_CANVAS, "update_canvas_overlay_underlay").args([
		canvas
	]).execute()
	if canvas is Canvas2D:
		canvas.refresh_viewport()


func get_preprocessor(cue: Cue):
	# [ original_image_data: ImageData, target: Object, method: String]
	if selected_preprocessor == DISABLE_PREPROCESSOR_KEYWORD:
		return
	
	original_image_data = cue.get_at(0, original_image_data, original_image_data == null)
	var target = cue.object_at(1, modifier, false)
	var method = cue.str_at(2, "_on_image_preprocessed", false)
	if original_image_data == null:
		l.g("Couldn't set image in " + name + " controller")
		return
	
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "set_text").args([
			Consts.HELP_DESC_PREPROCESSOR_IN_PROCESS]).execute()
	DiffusionServer.preprocess(
			target, 
			method, 
			original_image_data, 
			selected_preprocessor)
			


func set_preprocessor(cue: Cue):
	# [image_data: ImageData]
	var layer = canvas.select_layer(layer_name)
	var make_permanent = layer.is_empty()
	if layer == null:
		l.g("Couldn't retrieve the current layer in " + name)
		return
	
	var preprocessed_image = cue.get_at(0, null)
	var image_size
	if preprocessed_image == null:
		return
	
	var texture_node
	image_size = preprocessed_image.texture.get_size()
	if texture_material == null:
		texture_node = layer.draw_texture_at(
				preprocessed_image.texture, 
				Vector2.ZERO, 
				true)
	else:
		texture_node = layer.draw_texture_at(
				preprocessed_image.texture, 
				Vector2.ZERO, 
				true, 
				null, 
				texture_material)
	canvas.display_area = layer.limits
	canvas.update_shadow_areas()
	var image_rect = Rect2(- image_size / 2, image_size)
	canvas.fit_to_rect2(image_rect)
	board_owner.zoom_reset_area = image_rect
	canvas.add_texture_undoredo(texture_node, layer)
	if make_permanent:
		canvas.undoredo_queue.flush()
	
	if canvas is Canvas2D:
		yield(get_tree(), "idle_frame")
		layer.refresh_viewport()
		canvas.refresh_viewport()


func get_cn_config(cue: Cue) -> Cue:
	# [ active_image: Image, default: bool = true ]
	var active_image = cue.get_at(0, null)
	var default = cue.bool_at(1, true, false)
	if active_image == null:
		l.g("Couldn't create control net config in " + name + ". Missing ImageData in cue.")
		return null
	
	return cn_config.get_controlnet_config(active_image, default)


func get_active_image(_cue: Cue = null) -> Image:
	var layer = canvas.select_layer(layer_name)
	if layer == null:
		l.g("Couldn't retrieve the current layer in " + name)
		return null
	
	canvas.update_display_area()
	var layer_displayed_area = canvas.display_area
	layer_displayed_area.position -= layer.limits.position
	var image: Image = layer.get_image(layer_displayed_area)
	var base_image: Image = Image.new()
	var size = canvas.active_area_proportions
	base_image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	base_image.fill(Color(0, 0, 0, 0))
	image.resize(base_image.get_width(), base_image.get_height())
	base_image.blend_rect(image, Rect2(Vector2.ZERO, image.get_size()), Vector2.ZERO)
	return base_image


func clear(_cue: Cue = null):
	layer_name = ''


func reload_description(_cue: Cue = null):
	Cue.new(Consts.ROLE_DESCRIPTION_BAR, "add").opts({
		Consts.UI_CONTROL_MIDDLE_CLICK: Consts.HELP_DESC_MOVE_CAMERA,
		Consts.UI_CONTROL_SCROLL_UP: Consts.HELP_DESC_ZOOM_IN,
		Consts.UI_CONTROL_SCROLL_DOWN: Consts.HELP_DESC_ZOOM_OUT,
		Consts.UI_CONTROL_LEFT_CLICK: Consts.HELP_DESC_SAVE_OPTIONS_MENU,
	}).execute()


func _fill_menu():
	canvas.menu.add_tr_labeled_item(Consts.MENU_SAVE_CANVAS)
	canvas.menu.add_tr_labeled_item(Consts.MENU_SAVE_CANVAS_AS)
	canvas.menu.add_tr_labeled_item(Consts.MENU_SAVE_ACTIVE_IMAGE)
	canvas.menu.add_tr_labeled_item(Consts.MENU_SAVE_ACTIVE_IMAGE_AS)


func _on_Menu_option_pressed(label_id, _index_id):
	match label_id:
		Consts.MENU_SAVE_CANVAS:
			var path = Cue.new(Consts.ROLE_FILE_PICKER, "get_default_save_path").execute()
			_on_canvas_save_path_selected(path, false)
		Consts.MENU_SAVE_CANVAS_AS:
			Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
					self,
					"_on_canvas_save_path_selected",
					FileDialog.MODE_SAVE_FILE
				]).opts({
					tr("SUPPORTED_SAVE_IMAGE_FORMAT"): "*.png" # donetr
				}).execute()
		Consts.MENU_SAVE_ACTIVE_IMAGE:
			var path = Cue.new(Consts.ROLE_FILE_PICKER, "get_default_save_path").execute()
			_on_active_image_save_path_selected(path, false)
		Consts.MENU_SAVE_ACTIVE_IMAGE_AS:
			Cue.new(Consts.ROLE_FILE_PICKER,  "request_dialog").args([
					self,
					"_on_active_image_save_path_selected",
					FileDialog.MODE_SAVE_FILE
				]).opts({
					tr("SUPPORTED_SAVE_IMAGE_FORMAT"): "*.png" # donetr
				}).execute()


func _on_canvas_save_path_selected(path: String, overwrite: bool = true):
	ImageProcessor.save_image(canvas.get_canvas_image(), path, "canvas_image", true, overwrite)


func _on_active_image_save_path_selected(path: String, overwrite: bool = true):
	ImageProcessor.save_image(canvas.get_active_image(), path, "active_image", true, overwrite)


func _on_scroll_changed():
	var scrollbar = scroll.get_v_scrollbar()
	UIOrganizer.show_v_scroll_indicator(scrollbar, top_gradient, bottom_gradient, 8)


func _save_cues(_is_file_save):
	if controller_role.empty():
		l.g("Controller role empty at: " + name)
	if canvas is Canvas2D:
		var layers_data = canvas.get_save_data()
		Director.add_save_cue(Consts.SAVE, controller_role, "load_layers", [layers_data])


func load_layers(cue: Cue):
	# [ layer_daya ]
	var layers_data = cue.get_at(0, {})
	if canvas is Canvas2D:
		canvas.remove_all_layers()
		canvas.add_layers_data(layers_data)
