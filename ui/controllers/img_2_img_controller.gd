extends Controller

onready var denoising_strenght = $Container/Configs/Img2ImgConfigs/DenoisingStrenght
onready var cfg_scale = $Container/Configs/Img2ImgConfigs/CFGScale
onready var scroll = $Container
onready var top_gradient = $TopGradient
onready var bottom_gradient = $BottomGradient

var layer_name = ''
#var layer2d: Layer2D = null
var original_image_data: ImageData = null


func _ready():
	var error = connect("canvas_connected", self, "prepare_canvas")
	l.error(error)
	
	# Adding the scroll indicators
	if scroll is ScrollContainer and top_gradient != null and bottom_gradient != null:
		var gradient_group = Consts.THEME_MODULATE_GROUP_STYLE
		UIOrganizer.add_to_theme_by_modulate_group(top_gradient, gradient_group)
		UIOrganizer.add_to_theme_by_modulate_group(bottom_gradient, gradient_group)
		scroll.get_v_scrollbar().connect("changed", self, "_on_scroll_changed")
	
	Tutorials.subscribe(self, Tutorials.TUTM7)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM7:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM7_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM7_WEIGHT, [denoising_strenght])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_MOD_VISIBILITY, 
					[board_owner.overunderlay_tool])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM0_MOD_VISIBILITY_CONFIG, 
					[board_owner.overunderlay_tool])


func prepare_canvas(canvas: Control):
	canvas.add_to_group(Consts.UI_CANVAS_WITH_SHADOW_AREA)


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
	var layer_name_id = cue.str_at(0, '')
	var skip_save = cue.bool_at(1, false)
	canvas.mark_layer_skip_save_as(layer_name_id, skip_save)


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
	var target_mode = cue.str_at(0, '')
	var modifier = cue.get_at(1, null)
	Cue.new(Consts.ROLE_MODIFIERS_AREA, "update_canvas_overlay_underlay").args([
		canvas,
		target_mode,
		modifier
	]).execute()
	Cue.new(Consts.ROLE_CANVAS, "update_canvas_overlay_underlay").args([
		canvas
	]).execute()
	if canvas is Canvas2D:
		canvas.refresh_viewport()


func set_image(cue: Cue):
	# [image_data: ImageData]
	original_image_data = cue.get_at(0, null)
	if original_image_data == null:
		l.g("Couldn't set image in " + name + " controller")
		return
	
	var layer = canvas.select_layer(layer_name)
	if layer == null:
		l.g("Couldn't retrieve the current layer in " + name)
		return
	
	var image_size = original_image_data.texture.get_size()
	layer.draw_texture_at(
			original_image_data.texture, 
			Vector2.ZERO, 
			true)
	
	canvas.display_area = layer.limits
	canvas.update_shadow_areas()
	var image_rect = Rect2(- image_size / 2, image_size)
	canvas.fit_to_rect2(image_rect)
	board_owner.zoom_reset_area = image_rect


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


func get_img2img_dict(cue: Cue = null):
	# [ active_image: Image, default: bool = true ]
	var active_image = cue.get_at(0, null)
	
	var default = cue.bool_at(1, true, false)
	var dict = {} #DiffusionServer.api.img2img_dict.duplicate(true)
	if active_image == null:
		l.g("Couldn't create control net config in " + name + ". Missing ImageData in cue.")
		return
	
	dict[Consts.I2I_INIT_IMAGES] = active_image
	if not default:
		dict[Consts.I_DENOISING_STRENGTH] = denoising_strenght.get_value()
		dict[Consts.I_CFG_SCALE] = cfg_scale.get_value()
	
	return dict


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


func clear(_cue: Cue = null):
	var layer = canvas.select_layer(layer_name)
	if layer != null:
		layer.consolidate()
		layer.visible = false
	
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
	UIOrganizer.show_v_scroll_indicator(scrollbar, top_gradient, bottom_gradient)


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
