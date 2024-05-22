extends VBoxContainer


export(String, FILE, "*.tscn") var controller: String
export(String, FILE, "*.tscn") var canvas: String
export(bool) var is_main_board = false
export(bool) var has_overunderlay = true
export(bool) var separate_overunderlay = false
export(bool) var needs_tutorial = true
export(String) var tutorial_const = ''
export(String) var board_name = ''

onready var canvas_area = $CanvasArea/CanvasContainer
onready var tools_area = $CanvasArea/ToolsArea
onready var added_tools_area = $CanvasArea/ToolsArea/Margin/Tools/AddedTools
onready var tools_bottom_spacing = $CanvasArea/ToolsArea/Margin/Tools/Spacing
onready var overunderlay_tool = $CanvasArea/ToolsArea/Margin/Tools/OverunderlayButton
onready var zoom_settings = $CanvasArea/CanvasContainer/ZoomSettings
onready var zoom_tool = $CanvasArea/ToolsArea/Margin/Tools/ZoomButton
onready var zoom_slider = $CanvasArea/CanvasContainer/ZoomSettings/Container/Margin/Controls/Zoom
onready var overunderlay_settings = $CanvasArea/CanvasContainer/OverunderlaySettings
onready var modifier_lay_opacity = $"%ModifierLayOpacity"
onready var modifier_underlay_opacity = $"%ModifierUnderLayOpacity"
onready var modifier_overlay_opacity = $"%ModifierOverLayOpacity"
onready var gen_image_lay_opacity = $"%GenImageLayOpacity"
onready var gen_mask_lay_opacity = $"%GenMaskLayOpacity"
onready var switch_canvas_button = $Header/SwitchCanvasModifier
onready var tutorial_button = $Header/ShowGenerationArea/Tutorial
onready var board_label = $Header/ShowGenerationArea/Label

var tools_separation: int = 0
var canvas_node
var controller_node
var parent = null
var zoom_reset_area: Rect2 = Rect2(Vector2(-256, -256), Vector2(512, 512))


func _ready():
	overunderlay_tool.visible = false
	zoom_tool.visible = false
	if controller.empty() or canvas.empty():
		return
	
	# Setting up the controller and canvas
	tools_area.visible = false # this should only be visible if there are any tools
	parent = get_parent()
	canvas_node = load(canvas)
	controller_node = load(controller)
	if controller_node is PackedScene and canvas_node is PackedScene:
		controller_node = controller_node.instance()
		controller_node.board_owner = self
		add_child(controller_node)
		canvas_node = canvas_node.instance()
		canvas_node.board_owner = self
		canvas_area.add_child(canvas_node)
		canvas_area.move_child(canvas_node, 0)
		if controller_node.has_method("connect_canvas"):
			connect_board_visibility(controller_node)
			controller_node.connect_canvas(canvas_node)
	
	# Overlay-Underlay tool
	overunderlay_settings.visible = false
	if has_overunderlay:
		overunderlay_tool.visible = true
		overunderlay_tool.rect_min_size = Controller.get_tool_icon_size_vec2()
		if canvas_node is Canvas2D:
			_on_ModifierLayOpacity_value_changed(modifier_lay_opacity.get_value())
			_on_GenImageLayOpacity_value_changed(gen_image_lay_opacity.get_value())
			_on_GenMaskLayOpacity_value_changed(gen_mask_lay_opacity.get_value())
	
	if separate_overunderlay:
		modifier_lay_opacity.visible = false
		modifier_underlay_opacity.visible = true
		modifier_overlay_opacity.visible = true
	else:
		modifier_lay_opacity.visible = true
		modifier_underlay_opacity.visible = false
		modifier_overlay_opacity.visible = false
	
	_update_lays()
	
	# Zoom tool
	zoom_settings.visible = false
	if canvas_node is Canvas2D:
		zoom_tool.visible = true
		zoom_tool.rect_min_size = Controller.get_tool_icon_size_vec2()
		canvas_node.connect("zoom_changed", self, "_on_Canvas_zoom_changed")
	
	# Switch canvas-modifier button
	if is_main_board:
		switch_canvas_button.text = "SWITCH_TO_MODIFIER"
	else:
		switch_canvas_button.text = "SWITCH_TO_CANVAS"
	
	# Tutorials
	if tutorial_const.empty() and needs_tutorial:
		if parent is Control:
			l.g("Board '" + parent.name + "' doesn't have a tutorial code assigned.", 
					l.WARNING)
		else:
			l.g("Board at '" + get_path() + "' doesn't have a tutorial code assigned", 
					l.WARNING)
	elif tutorial_const.empty():
		tutorial_button.visible = false
	
	# Setting up the board title
	if board_name.empty():
		var aux
		if parent is Control:
			aux = parent.name.capitalize()
			name = aux.replace(" ", "")
			aux = aux.replace(" ", "_")
			aux = aux.replace("BOARD", "MODE").to_upper()
			board_label.text = aux
	else:
		board_label.text = board_name
		name = board_name.capitalize().replace(" ", "")
	
	yield(get_tree(), "idle_frame")
	tools_bottom_spacing.rect_min_size.y = added_tools_area.rect_position.y
	tools_separation = added_tools_area.get_constant("separation")
	tools_bottom_spacing.rect_min_size.y -= tools_separation


func show_board():
	if parent == null:
		return
	
	parent.visible = true
	if controller_node is Controller:
		controller_node.add_to_description_group() # for the description bar


func _update_lays():
	if separate_overunderlay:
		_on_ModifierOverLayOpacity_value_changed(modifier_overlay_opacity.get_value())
		_on_ModifierUnderLayOpacity_value_changed(modifier_underlay_opacity.get_value())
	else:
		_on_ModifierLayOpacity_value_changed(modifier_lay_opacity.get_value())


func hide_board():
	if parent == null:
		return
	
	if not parent.visible:
		# No need to hide if it already is
		return
	
	if controller_node is Controller:
		controller_node._on_Controller_hiding()
		controller_node.remove_from_description_group() # for the description bar
	
	parent.visible = false


func show_alt_board_switch():
	switch_canvas_button.visible = true


func hide_alt_board_switch():
	switch_canvas_button.visible = false
	


func connect_board_visibility(controller_node_: Control):
	if parent == null:
		return
	
	var e = controller_node_.connect("visible_board_requested", self, "show_board")
	l.error(e, l.CONNECTION_FAILED)


func add_tool_icon(button_icon: TextureButton):
	tools_area.visible = true
	added_tools_area.add_child(button_icon)


func _on_SwitchCanvasModifier_pressed():
	if is_main_board:
		Cue.new(Consts.ROLE_GENERATION_INTERFACE, "show_modifier_board").execute()
	else:
		Cue.new(Consts.ROLE_GENERATION_INTERFACE, "show_main_board").execute()


func _on_OverunderlayButton_toggled(button_pressed):
	if canvas_node is Canvas2D:
		canvas_node.lay.set_visibility(canvas_node.MODIFIERS_OVERLAY, button_pressed)
		canvas_node.lay.set_visibility(canvas_node.MODIFIERS_UNDERLAY, button_pressed)
		canvas_node.lay.set_visibility(canvas_node.GEN_IMAGE_OVERLAY, button_pressed)
		canvas_node.lay.set_visibility(canvas_node.GEN_MASK_OVERLAY, button_pressed)


func _on_OverunderlayButton_extra_options_selected():
	zoom_settings.visible = false
	overunderlay_settings.visible = not overunderlay_settings.visible


func _on_OverunderlayContainer_mouse_exited_areas():
	overunderlay_settings.visible = false


func _on_ModifierLayOpacity_value_changed(value):
	if canvas_node is Canvas2D:
		canvas_node.lay.set_alpha(canvas_node.MODIFIERS_OVERLAY, value)
		canvas_node.lay.set_alpha(canvas_node.MODIFIERS_UNDERLAY, value)


func _on_ModifierOverLayOpacity_value_changed(value):
	if canvas_node is Canvas2D:
		canvas_node.lay.set_alpha(canvas_node.MODIFIERS_OVERLAY, value)


func _on_ModifierUnderLayOpacity_value_changed(value):
	if canvas_node is Canvas2D:
		canvas_node.lay.set_alpha(canvas_node.MODIFIERS_UNDERLAY, value)


func _on_GenImageLayOpacity_value_changed(value):
	if canvas_node is Canvas2D:
		canvas_node.lay.set_alpha(canvas_node.GEN_IMAGE_OVERLAY, value)


func _on_GenMaskLayOpacity_value_changed(value):
	if canvas_node is Canvas2D:
		canvas_node.lay.set_alpha(canvas_node.GEN_MASK_OVERLAY, value)


func _on_Tutorial_pressed():
	Tutorials.run_with_const(tutorial_const, false)


func _on_Zoom_value_changed(percentage_value):
	if zoom_slider == null:
		return
	
	if percentage_value == 0:
		percentage_value = 12.5
	
	# On godot 3, zoom < 1 means we get closer, zoom > 1 farther
	# This is on the inverse of how it generally is (more zoom = closer, less zoom = farther)
	# hence why we invert it with the division
	var value = 100 / percentage_value
	if canvas_node is Canvas2D:
		canvas_node.set_zoom(value)


func _on_ResetZoom_pressed():
	if canvas_node is Canvas2D:
		canvas_node.fit_to_rect2(zoom_reset_area)
		canvas_node.display_area = zoom_reset_area


func _on_ZoomButton_extra_options_selected():
	overunderlay_settings.visible = false
	zoom_settings.visible = not overunderlay_settings.visible


func _on_ZoomContainer_mouse_exited_areas():
	zoom_settings.visible = false


func _on_ZoomButton_pressed():
	_on_ZoomButton_extra_options_selected()

func _on_Canvas_zoom_changed(value):
	if value == 0:
		value = 0.2
	
	# On godot 3, zoom < 1 means we get closer, zoom > 1 farther
	# This is on the inverse of how it generally is (more zoom = closer, less zoom = farther)
	# hence why we invert it with the division
	var percentage_value = 1 / value * 100
	zoom_slider.set_value(percentage_value, false)


func _on_Tools_resized():
	if added_tools_area == null:
		return
	if added_tools_area.get_child_count() == 0:
		return
	
	yield(get_tree(), "idle_frame")
	var first_child = added_tools_area.get_child(0)
	var empty_space = first_child.rect_position.y
	var last_child = added_tools_area.get_child(added_tools_area.get_child_count() - 1)
	var spacing_full_size = tools_bottom_spacing.rect_size.y + tools_separation
	# We add the empty space after the last child
	empty_space += added_tools_area.rect_size.y 
	empty_space -= last_child.rect_position.y 
	empty_space -= last_child.rect_size.y
	if tools_bottom_spacing.visible:
		empty_space += spacing_full_size
	
	if empty_space <= spacing_full_size + first_child.rect_min_size.y * 2:
		added_tools_area.alignment = added_tools_area.ALIGN_END
		tools_bottom_spacing.visible = false
	else:
		added_tools_area.alignment = added_tools_area.ALIGN_CENTER
		tools_bottom_spacing.visible = true
