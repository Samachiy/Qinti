extends Controller



onready var regions_container = $ScrollContainer/Configs/ScrollContainer/RegionsList
onready var regions_scroll_container = $ScrollContainer/Configs/ScrollContainer
onready var scroll = $ScrollContainer
onready var prompt = $ScrollContainer/Configs/ToolControllers/Prompt
onready var top_gradient= $TopGradient
onready var bottom_gradient= $BottomGradient

var layer_name = ''
var current_layer = null
var regions_data: Dictionary = {} # { child1: [rect2_1, data_dict1], child2: ... ]
var regions_to_entry: Dictionary = {} # { region_node1: entry1, region_node2: entry2, ... }
var entry_button = preload("res://ui/controllers/regional_prompting_entry.tscn")
var current_entry: Control = null

func _ready():
	var error = connect("canvas_connected", self, "prepare_canvas")
	l.error(error)
	
	# Adding the scroll indicators
	if scroll is ScrollContainer and top_gradient != null and bottom_gradient != null:
		var gradient_group = Consts.THEME_MODULATE_GROUP_STYLE
		UIOrganizer.add_to_theme_by_modulate_group(top_gradient, gradient_group)
		UIOrganizer.add_to_theme_by_modulate_group(bottom_gradient, gradient_group)
		scroll.get_v_scrollbar().connect("changed", self, "_on_scroll_changed")
	
	Tutorials.subscribe(self, Tutorials.TUTM1)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM1:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DETAILS, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DESC_BOX, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_COPY, [])


func clear(_cue: Cue = null):
	if current_entry != null:
		active_tool.unfocus_region(current_entry.region)
		current_entry = null
	
	for child in regions_container.get_children():
		child.queue_free()
	
	var layer = canvas.select_layer(layer_name)
	if layer is Control:
		layer.visible = false
	
	current_layer = null
	layer_name = ''


func get_data_cue(_cue: Cue = null):
	var cue = Cue.new(Consts.ROLE_CONTROL_REGION_PROMPT, 'set_data_cue')
	
	cue.args([
		canvas.display_area,
		layer_name,
		])
	
	return cue


func get_active_regions(_cue: Cue = null):
	var active_regions = [] # [ [rect1, data_dict1], [rect2, data_dict2], ... ]
	if current_layer is RegionLayer2D:
		active_regions = current_layer.get_regions_data(true).values()
		active_regions.invert() # so that the lowest priority are first, higher last
	
	return active_regions


func set_data_cue(cue: Cue):
	clear()
	var display_area = cue.get_at(0, Rect2(Vector2.ZERO, Vector2(512, 512)))
	var layer_name_ = cue.get_at(1, '')
	prepare_regions(Cue.new('', '').args([layer_name_]))
	canvas.display_area = display_area
	canvas.fit_to_rect2(display_area)


func _fill_menu():
	pass # No menu needed here


func _on_Menu_option_pressed(_label_id, _index_id):
	pass # No menu needed here


func reload_description(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'reload_description' has not been overriden yet on Controller: " + 
	filename)


func prepare_regions(cue: Cue):
	# [layer_name: String]
	canvas._on_resized()
	var layer_id = cue.get_at(0, '')
	current_layer = canvas.select_layer(layer_id)
	if current_layer == null:
		layer_id = canvas.add_region_layer(layer_id)
		current_layer = canvas.select_layer(layer_id)
	
	current_layer.visible = true
	layer_name = layer_id
	if current_layer is RegionLayer2D:
		regions_data = current_layer.get_regions_data(false)
		load_entries()
		current_layer.show_regions()
	return layer_id


func prepare_canvas(canvas: Control):
	canvas.add_to_group(Consts.UI_CANVAS_WITH_SHADOW_AREA)


func load_entries():
	for node in regions_data.keys():
		add_entry(node)


func add_entry(node: Node):
	var entry = entry_button.instance()
	regions_container.add_child(entry)
	entry.set_info(node, '')
	entry.connect("display_info_requested", self, "_on_RegionEntry_pressed")
	node.modulate.a = 0.5
	regions_to_entry[node] = entry
	return entry


func add_missing_regions():
	if current_layer is RegionLayer2D:
		regions_data = current_layer.get_regions_data(false)
	
	for node in regions_data.keys():
		if not node in regions_to_entry:
			add_entry(node)


func select_region(region_node):
	if current_entry != null:
		active_tool.unfocus_region(current_entry.region)
	
	if region_node is RegionArea2D:
		var info = regions_data.get(region_node, [])
		var data_dict
		if info is Array and info.size() >= 2:
			data_dict = info[1]
		else:
			l.g("Couldn't load region for regional prompt, region info: " + str(info))
		
		if data_dict is Dictionary:
			prompt.text = data_dict.get(RegionArea2D.DESCRIPTION, "")
		else:
			l.g("Couldn't load region for regional prompt, region data: " + str(data_dict))
		
		current_entry = regions_to_entry.get(region_node, null)
		active_tool.focus_region(current_entry.region)


func _on_RegionEntry_pressed(region_node):
	select_region(region_node)


func _on_Prompt_text_changed():
	if current_entry != null:
		current_entry.set_text(prompt.text)
		current_entry.region.data[RegionArea2D.DESCRIPTION] = prompt.text


func get_current_entry():
	return current_entry


func get_current_region():
	if current_entry != null:
		return current_entry.region
	else:
		return null


func get_active_image(_cue: Cue = null) -> Image:
	canvas.update_display_area()
	var image: Image = canvas.get_active_image()
	return image


func _on_scroll_changed():
	var scrollbar = scroll.get_v_scrollbar()
	UIOrganizer.show_v_scroll_indicator(scrollbar, top_gradient, bottom_gradient)


func calculate_region_node_rect(region_node: RegionArea2D):
	var display_rect = canvas.display_area
	var region_rect = region_node.get_rect()
	var resul_pos = canvas.convert_back_position(region_rect.position)
	var shadows = Vector2(canvas.left_shadow.rect_min_size.x, canvas.top_shadow.rect_min_size.y)
	resul_pos = resul_pos - shadows
	var active_area_prop = canvas.active_area_proportions
	var size_prop = active_area_prop / display_rect.size
	var resul_size =  region_rect.size * size_prop
	return Rect2(resul_pos, resul_size)
