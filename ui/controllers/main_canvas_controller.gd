extends Controller

const MAIN_LAYER_NAME = 'main'
const DEFAULT_SAMPLER = 'Euler'
const DEFAULT_UPSCALER = 'Lanczos'
const DEFAULT_HI_RES_START_AT = 512 * 512

const HI_RES_NONE = "HI_RES_NONE"
const HI_RES_AUTO = "HI_RES_AUTO"
const HI_RES_MANUAL = "HI_RES_MANUAL"
const HI_RES_UPSCALE_ONLY_AUTO = "HI_RES_UPSCALE_ONLY_AUTO"
const HI_RES_UPSCALE_ONLY_MANUAL = "HI_RES_UPSCALE_ONLY_MANUAL"

onready var steps = $Configs/Settings/Tab/BASIC_PARAMS/Steps
onready var cfg_scale = $Configs/Settings/Tab/BASIC_PARAMS/CFGScale
onready var batch_size = $Configs/Settings/Tab/BATCH_PARAMS/BatchSize
onready var batch_count = $Configs/Settings/Tab/BATCH_PARAMS/BatchCount
onready var clip_skip = $Configs/Settings/Tab/BASIC_PARAMS/ClipSkip
onready var esdn = $Configs/Settings/Tab/BASIC_PARAMS/ESDN/ESDN
onready var tiling = $Configs/Settings/Tab/BASIC_PARAMS/CheckBoxes/Tiling
onready var restore_faces = $Configs/Settings/Tab/BASIC_PARAMS/CheckBoxes/RestoreFaces
onready var hi_res_type = $Configs/Settings/Tab/HI_RES_PARAMS/HiResType
onready var hi_res_start_at = $Configs/Settings/Tab/HI_RES_PARAMS/StartAt
onready var hi_res_from_to_label = $Configs/Settings/Tab/HI_RES_PARAMS/FromTo
onready var hi_res_steps = $Configs/Settings/Tab/HI_RES_PARAMS/Steps
onready var hi_res_upscale_by = $Configs/Settings/Tab/HI_RES_PARAMS/UpscaleBy
onready var hi_res_upscalers = $Configs/Settings/Tab/HI_RES_PARAMS/Upscaler
onready var hi_res_denoise = $Configs/Settings/Tab/HI_RES_PARAMS/DenoisingStrenght
onready var modify_gen_area_tool = $Configs/Settings/ToolControllers/ModifyGenerationAreaTool
onready var brush_tool = $Configs/Settings/ToolControllers/BrushToolController
onready var eraser_tool = $Configs/Settings/ToolControllers/EraserToolController
onready var samplers = $Configs/Settings/Tab/BASIC_PARAMS/Sampler
onready var scroll = $Configs
onready var top_gradient = $TopGradient
onready var bottom_gradient = $BottomGradient
onready var inpaint_brush_tool = $Configs/Settings/ToolControllers/InpaintBrushController
onready var inpaint_eraser_tool = $Configs/Settings/ToolControllers/InpaintEraserController

var generation_area: GenerationArea2D = null
var main_canvas_layer: Layer2D = null
var selected_sampler: String = ''
var image_viewer_relay: ImageViewerRelay = null
var start_at_hr_values: Dictionary = {
	"256 x 256": 256 * 256,
	"512 x 512": 512 * 512,
	"768 x 768": 768 * 768,
	"1024 x 1024": 1024 * 1024,
}
var gen_area_image: Image  = null
var gen_area_mask: Image = null

func _ready():
	Roles.request_role(self, Consts.ROLE_CANVAS, true)
	Roles.request_role_on_roles_cleared(self, Consts.ROLE_CANVAS)
	Roles.request_role(board_owner, Consts.ROLE_ACTIVE_BOARD, true)
	l.p(board_owner.name)
	var e = DiffusionServer.connect("samplers_refreshed", self, "_on_samplers_refreshed")
	l.error(e, l.CONNECTION_FAILED)
	e = DiffusionServer.connect("upscalers_refreshed", self, "_on_upscalers_refreshed")
	l.error(e, l.CONNECTION_FAILED)
	
	var gradient_group = Consts.THEME_MODULATE_GROUP_STYLE
	UIOrganizer.add_to_theme_by_modulate_group(top_gradient, gradient_group)
	UIOrganizer.add_to_theme_by_modulate_group(bottom_gradient, gradient_group)
	scroll.get_v_scrollbar().connect("changed", self, "_on_scroll_changed")
	
	# Adding Hi-Res type values
	hi_res_type.add_tr_labeled_item(HI_RES_AUTO)
	hi_res_type.add_tr_labeled_item(HI_RES_MANUAL)
	#hi_res_type.add_tr_labeled_item(HI_RES_UPSCALE_ONLY_AUTO) # Not available yet
	#hi_res_type.add_tr_labeled_item(HI_RES_UPSCALE_ONLY_MANUAL) # Not available yet
	hi_res_type.add_tr_labeled_item(HI_RES_NONE)
	if not hi_res_type.select_flag_value():
		hi_res_type.select_by_label(HI_RES_AUTO)
	
	# Adding Hi-Res start at values
	for value in start_at_hr_values.keys():
		hi_res_start_at.add_labeled_item(value, start_at_hr_values[value])
	if not hi_res_start_at.select_flag_value():
		hi_res_start_at.select_by_label(DEFAULT_HI_RES_START_AT)
	
#	Director.connect_load_ready(self, "_on_load_ready")
	Tutorials.subscribe(self, Tutorials.TUT1)
	Tutorials.subscribe(self, Tutorials.TUT2)
	Tutorials.subscribe(self, Tutorials.TUT3)
	Tutorials.subscribe(self, Tutorials.TUT8)
	Tutorials.subscribe(self, Tutorials.TUT9)
	Tutorials.subscribe(self, Tutorials.TUT10)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUT1:
			tutorial_seq.add_tr_named_step(Tutorials.TUT1_WELCOME, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUT1_PARAMETERS, [scroll])
			tutorial_seq.add_tr_named_step(Tutorials.TUT1_TOOLS, [board_owner.tools_area])
		Tutorials.TUT2:
			tutorial_seq.add_tr_named_step(Tutorials.TUT2_APPLY_GENERATION, 
					[canvas.message_area.msg_apply_button, 
					canvas.message_area.msg_apply_copy_button])
		Tutorials.TUT3:
			var step: TutorialStep
			var recent_img = Cue.new(Consts.ROLE_TOOLBOX, "get_last_recent_thumbnail").execute()
			var mod_area = Roles.get_node_by_role(Consts.ROLE_MODIFIERS_AREA)
			if recent_img == null:
				recent_img = Roles.get_node_by_role(Consts.ROLE_TOOLBOX)
			step = tutorial_seq.add_tr_named_step(Tutorials.TUT3_LOAD_IMAGE_DRAG, 
					[canvas.preview, recent_img])
			step.drag(recent_img, canvas.preview)
			step = tutorial_seq.add_tr_named_step(Tutorials.TUT3_CONTROL_NET_DRAG, 
					[mod_area, recent_img])
			step.drag(recent_img, mod_area)
			tutorial_seq.add_tr_named_step(Tutorials.TUT3_PREVIEW_DRAG, [canvas.preview])
		Tutorials.TUT8:
			tutorial_seq.add_tr_named_step(Tutorials.TUT8_CANVAS, [canvas.viewport_container])
			tutorial_seq.add_tr_named_step(Tutorials.TUT8_ACTIVE_IMAGE, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUT8_PREVIEW, [canvas.preview])
		Tutorials.TUT9:
			open_board()
			inpaint_brush_tool.select_tool()
			scroll.get_v_scrollbar().value = 0
			tutorial_seq.add_tr_named_step(Tutorials.TUT9_DEFINITION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUT9_TOOLS, [inpaint_brush_tool.button])
			tutorial_seq.add_tr_named_step(Tutorials.TUT9_MASK, 
					[inpaint_brush_tool.inpaint_button])
			tutorial_seq.add_tr_named_step(Tutorials.TUT9_ERASER, 
					[inpaint_eraser_tool.button, inpaint_brush_tool.clear_mask_button])
		Tutorials.TUT10:
			open_board()
			modify_gen_area_tool.select_tool()
			scroll.get_v_scrollbar().value = 0
			tutorial_seq.add_tr_named_step(Tutorials.TUT10_DEFINITION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUT10_TOOL, [modify_gen_area_tool.button])
			tutorial_seq.add_tr_named_step(Tutorials.TUT10_EXTEND, 
					[modify_gen_area_tool.outpaint_button])


func _on_load_ready(_is_loading_from_file):
	pass


func _on_Controller_hiding():
	gen_area_image = generation_area.get_contained_image()
	gen_area_mask = generation_area.get_contained_mask()
	pause_layer()


func update_canvas_overlay_underlay(cue: Cue):
	# [ canvas: Control ]
	var target_canvas = cue.get_at(0, null)
	if target_canvas is Canvas2D:
		target_canvas.lay.clear(target_canvas.GEN_IMAGE_OVERLAY)
		target_canvas.lay.append(target_canvas.GEN_IMAGE_OVERLAY, gen_area_image)
		target_canvas.lay.refresh(target_canvas.GEN_IMAGE_OVERLAY, null)
		target_canvas.lay.clear(target_canvas.GEN_MASK_OVERLAY)
		target_canvas.lay.append(target_canvas.GEN_MASK_OVERLAY, gen_area_mask)
		target_canvas.lay.refresh(target_canvas.GEN_MASK_OVERLAY, null)


func _on_CanvasController_canvas_connected(_canvas: Node):
	canvas.grid.set_as_grid()
	canvas.add_generation_area() # add genarea before layer to allow genarea to connect to layer
	prepare_layer()
	generation_area = canvas.generation_area
	canvas.message_area.connect_message_area(self, 
			"_on_ApplyGeneration_pressed", 
			"_on_ApplyGenerationCopy_pressed", 
			"_on_Regenerate_pressed", 
			"_on_DiscardGeneration_pressed",
			"_on_prev_pressed",
			"_on_next_pressed")
	Roles.request_role(self, Consts.ROLE_GEN_AREA, true)
	Roles.request_role_on_roles_cleared(self, Consts.ROLE_GEN_AREA)


func set_images_in_generation_area(cue: Cue):
	# [ image_data1, image_data2, image_data3, ... ]
	# { 'relay': image_viewer_relay 
	#	'focus': false }
	if generation_area == null:
		l.g("Can't load generated images in generation area, generation area doesn't exist")
		return
	
	var relay = cue.object_option('relay')
	var focus = cue.bool_option('focus', false)
	if relay is ImageViewerRelay:
		image_viewer_relay = relay
		image_viewer_relay.connect_relay(self, "_on_image_change_requested")
	
	generation_area.set_images_data(cue._arguments)
	var change_tool: bool = true
	if brush_tool.visible or eraser_tool.visible or \
	inpaint_brush_tool.visible or inpaint_eraser_tool.visible:
		change_tool = false
	
	if change_tool:
		select_main_tool() # Selects modify gen area tool
	
	canvas.refresh_viewport()
	main_canvas_layer = canvas.select_layer(MAIN_LAYER_NAME)
	canvas.current_layer = generation_area
	if focus:
		canvas.display_area = generation_area.limits
	canvas.message_area.show_area(focus)
	if cue._arguments.size() > 1:
		canvas.message_area.enable_next_prev(true)
	else:
		canvas.message_area.enable_next_prev(false)


func select_main_tool(_cue: Cue = null):
	modify_gen_area_tool.select_tool()


func get_generation_area(_cue: Cue = null):
	if generation_area != null:
		return generation_area.get_rect2()


func prepare_layer():
	canvas._on_resized()
	var layer = canvas.select_layer(MAIN_LAYER_NAME)
	if layer == null:
		canvas.add_layer(MAIN_LAYER_NAME)
	
	main_canvas_layer = canvas.select_layer(MAIN_LAYER_NAME)
	main_canvas_layer.visible = true


func pause_layer(_cue: Cue = null):
	l.p("Paused controller" + name)
	var layer = canvas.select_layer(MAIN_LAYER_NAME)
	if layer != null:
		layer.consolidate()


func consolidate_layer(_cue: Cue = null):
	var layer = canvas.select_layer(MAIN_LAYER_NAME)
	if layer != null:
		layer.consolidate()


func apply_parameters_to_api(_cue: Cue = null):
	var override_settings: Dictionary = {
		Consts.SDO_CLIP_SKIP: clip_skip.get_value(),
		Consts.SDO_ENSD: int(esdn.text),
	}
	
	var width = modify_gen_area_tool.get_width()
	var height = modify_gen_area_tool.get_height()
	var dict: Dictionary = {
		Consts.I_STEPS: steps.get_value(),
		Consts.I_WIDTH: width,
		Consts.I_HEIGHT: height,
		Consts.I_CFG_SCALE: cfg_scale.get_value(),
		Consts.I_BATCH_SIZE: batch_size.get_value(),
		Consts.I_N_ITER: batch_count.get_value(),
#		Consts.I_SEED: int(seed_.text),
		Consts.I_TILING: tiling.pressed,
		Consts.I_RESTORE_FACES: restore_faces.pressed,
		Consts.I_OVERRIDE_SETTINGS: override_settings,
		Consts.I_SAMPLER_NAME: samplers.get_selected()
	}
	
	var has_hi_res: bool = true
	match hi_res_type.get_selected():
		HI_RES_AUTO:
			var hi_res = calculate_hi_res_base_measures(
					width, 
					height, 
					# selected_id was also used to store the max_area number
					hi_res_start_at.get_selected())
			dict[Consts.I_WIDTH] = hi_res.x
			dict[Consts.I_HEIGHT] = hi_res.y
			#dict[Consts.T2I_HR_RESIZE_X] = 0
			#dict[Consts.T2I_HR_RESIZE_Y] = 0
			dict[Consts.T2I_HR_SCALE] = hi_res.upscale_by
		HI_RES_MANUAL:
			var upscale_by = clamp(hi_res_upscale_by.get_value(), 1, 4)
			dict[Consts.T2I_HR_RESIZE_X] = int(width / upscale_by)
			dict[Consts.T2I_HR_RESIZE_Y] = int(height / upscale_by)
			#dict[Consts.T2I_HR_RESIZE_X] = 0
			#dict[Consts.T2I_HR_RESIZE_Y] = 0
			dict[Consts.T2I_HR_SCALE] = upscale_by
		HI_RES_UPSCALE_ONLY_AUTO:
			pass # not in use yet
		HI_RES_UPSCALE_ONLY_MANUAL:
			pass # not in use yet
		HI_RES_NONE, _:
			has_hi_res = false
	
	if dict.get(Consts.T2I_HR_SCALE, 1) <= 1:
		has_hi_res = false
	
	if has_hi_res:
		dict[Consts.T2I_ENABLE_HR] = true
		dict[Consts.T2I_HR_SECOND_PASS_STEPS] = hi_res_steps.get_value()
		dict[Consts.I_DENOISING_STRENGTH] = hi_res_denoise.get_value()
		dict[Consts.T2I_HR_UPSCALER] = hi_res_upscalers.get_selected()
#		dict["latent_sampler"] = "UniPC"
#		dict[Consts.T2I_HR_UPSCALER] = "Latent"
	if not selected_sampler.empty():
		dict[Consts.I_SAMPLER_NAME] = selected_sampler
	
	Cue.new(Consts.ROLE_API, "apply_parameters").opts(dict).execute()


func calculate_hi_res_base_measures(target_width: int, target_height: int, max_area_pixels: int):
	# returns: { x: int, y: int, upscale_by: float }
	var target_area_pix = target_height * target_width
	if max_area_pixels >= target_area_pix:
		return {'x': target_width, 'y': target_height, 'upscale_by': 1}
	else:
		var ratio = sqrt(target_area_pix / max_area_pixels)
		var base_width = round(target_width / ratio)
		var base_height = round(target_height / ratio)
		return {'x': int(base_width), 'y': int(base_height), 'upscale_by': stepify(ratio, 0.05)}


func paste_current_gen_image():
	Tutorials.run_with_name(Tutorials.TUT3, true, [Tutorials.TUT1, Tutorials.TUT2])
	var texture_node
	var texture = ImageTexture.new()
	texture.create_from_image(generation_area.get_visible_image())
	texture_node = main_canvas_layer.draw_texture_at(
			texture, 
			generation_area.limits.position, 
			false)
	
	canvas.add_texture_undoredo(texture_node, main_canvas_layer)


func _on_upscalers_refreshed():
	var upscalers_array = DiffusionServer.upscalers
	if upscalers_array is Array and not upscalers_array.empty():
		hi_res_upscalers.clear()
		for upscaler_name in DiffusionServer.upscalers:
			hi_res_upscalers.add_tr_labeled_item(upscaler_name)
		
		var default_upscaler: String  = DiffusionServer.api.default_upscaler
		if hi_res_upscalers.select_flag_value():
			pass # just selecting, nothing to do here
		elif default_upscaler.empty():
			hi_res_upscalers.select(0)
		elif hi_res_upscalers.select_by_label(default_upscaler, false):
			pass # just selecting, nothing to do here
		else:
			hi_res_upscalers.select(0)


func _on_samplers_refreshed():
	var samplers_array = DiffusionServer.samplers
	if samplers_array is Array and not samplers_array.empty():
		samplers.clear()
		for sampler_name in DiffusionServer.samplers:
			samplers.add_tr_labeled_item(sampler_name)
		
		
		var default_sampler: String = DiffusionServer.api.default_upscaler
		if samplers.select_flag_value():
			pass # just selecting, nothing to do here
		elif default_sampler.empty():
			samplers.select(0)
		elif samplers.select_by_label(DEFAULT_SAMPLER, false):
			pass # just selecting, nothing to do here
		else:
			samplers.select(0)


func _on_Sampler_option_selected(label_id, _index_id):
	selected_sampler = label_id


func _on_ApplyGeneration_pressed():
	paste_current_gen_image()
	_on_DiscardGeneration_pressed()


func _on_ApplyGenerationCopy_pressed():
	paste_current_gen_image()
	canvas.current_layer = generation_area


func _on_DiscardGeneration_pressed():
	canvas.select_layer(MAIN_LAYER_NAME)
	canvas.message_area.hide_area()
	image_viewer_relay = null
	generation_area.clear_images()


func _on_prev_pressed():
	generation_area.prev(image_viewer_relay)


func _on_next_pressed():
	generation_area.next(image_viewer_relay)


func _on_image_change_requested(index, _image: ImageData):
	generation_area.set_image_num(index)
	canvas.refresh_viewport()


func _on_Regenerate_pressed():
	DiffusionServer.regenerate()


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


func _on_UpscaleBy_value_changed(value):
	if hi_res_from_to_label == null:
		return
	
	if not hi_res_from_to_label.visible:
		return
	
	var width = modify_gen_area_tool.get_width()
	var height = modify_gen_area_tool.get_height()
	var upscale_by = clamp(value, 1, 4)
	var base_width = width / upscale_by
	var base_height = height / upscale_by
	hi_res_from_to_label.text = str(base_width) + " x " + str(base_height)
	hi_res_from_to_label.text += " -> " + str(width) + " x " + str(height)
	


func _on_HiResType_option_selected(label_id, _index_id):
	match label_id:
		HI_RES_AUTO:
			hi_res_start_at.visible = true
			hi_res_upscale_by.visible = false
			hi_res_from_to_label.visible = false
			# Show common hi_res controls
			hi_res_steps.visible = true
			hi_res_denoise.visible = true
			hi_res_upscalers.visible = true
		HI_RES_MANUAL:
			hi_res_start_at.visible = false
			hi_res_upscale_by.visible = true
			hi_res_from_to_label.visible = true
			_on_UpscaleBy_value_changed(hi_res_upscale_by.get_value())
			# Show common hi_res controls
			hi_res_steps.visible = true
			hi_res_denoise.visible = true
			hi_res_upscalers.visible = true
		HI_RES_NONE, _:
			hi_res_start_at.visible = false
			hi_res_from_to_label.visible = false
			hi_res_upscale_by.visible = false
			hi_res_steps.visible = false
			hi_res_denoise.visible = false
			hi_res_upscalers.visible = false


func _on_scroll_changed():
	var scrollbar = scroll.get_v_scrollbar()
	UIOrganizer.show_v_scroll_indicator(scrollbar, top_gradient, bottom_gradient)


func _save_cues(_is_file_save):
	if canvas is Canvas2D:
		var layers_data = canvas.get_save_data()
		Director.add_save_cue(Consts.SAVE, Consts.ROLE_CANVAS, "load_layers", [layers_data])


func load_layers(cue: Cue):
	# [ layer_daya ]
	var layers_data = cue.get_at(0, {})
	if canvas is Canvas2D:
		canvas.remove_all_layers()
		canvas.add_layers_data(layers_data)
	
