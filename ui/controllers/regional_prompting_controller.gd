extends Controller



onready var regions_container = $ScrollContainer/Configs/ScrollContainer/RegionsList
onready var regions_scroll_container = $ScrollContainer/Configs/ScrollContainer
onready var prompt = $ScrollContainer/Configs/ToolControllers/Prompt

var layer_name = ''
var regions_data: Dictionary = {} # { child1: [rect2_1, data_dict1], child2: ... ]
var regions_to_entry: Dictionary = {} # { region_node1: entry1, region_node2: entry2, ... }
var entry_button = preload("res://ui/controllers/regional_prompting_entry.tscn")
var current_entry: Control = null

func _ready():
	Tutorials.subscribe(self, Tutorials.TUTM1)


func _tutorial(tutorial_seq: TutorialSequence):
	match tutorial_seq.name:
		Tutorials.TUTM1:
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DESCRIPTION, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DETAILS, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_DESC_BOX, [])
			tutorial_seq.add_tr_named_step(Tutorials.TUTM1_COPY, [])


func clear(_cue: Cue = null):
	for child in regions_container.get_children():
		child.queue_free()


func get_data_cue(_cue: Cue = null):
	var active_regions = [] # [ [rect1, data_dict1], [rect2, data_dict2], ... ]
	var inactive_regions = [] # [ [rect1, data_dict1], [rect2, data_dict2], ... ]
	return Cue.new(controller_role, "set_data_cue").args([active_regions, inactive_regions])


func set_data_cue(_cue: Cue):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'set_data_cue' has not been overriden yet on Controller: " + 
	name)


func _fill_menu():
	l.g("The function '_fill_menu' has not been overriden yet on Controller: " + 
	filename)


func _on_Menu_option_pressed(_label_id, _index_id):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function '_on_Menu_option_pressed' has not been overriden yet on Controller: " + 
	filename)


func reload_description(_cue: Cue = null):
	# This function will be called more times on it's lifespan, program it accordingly
	l.g("The function 'reload_description' has not been overriden yet on Controller: " + 
	filename)


func prepare_regions(cue: Cue):
	# [layer_name: String]
	canvas._on_resized()
	var layer_id = cue.get_at(0, '')
	var layer = canvas.select_layer(layer_id)
	if layer == null:
		layer_id = canvas.add_region_layer(layer_id)
		layer = canvas.select_layer(layer_id)
	
	layer.visible = true
	layer_name = layer_id
	if layer is RegionLayer2D:
		regions_data = layer.get_regions_data()
	return layer_id


func load_entries():
	for node in regions_data.keys():
		add_entry(node)


func add_entry(node: Node):
	var entry = entry_button.instance()
	regions_container.add_child(entry)
	entry.region_node = node
	entry.connect("display_info_requested", self, "_on_RegionEntry_pressed")
	node.modulate.a = 0.5
	regions_to_entry[node] = entry
	return entry
	


func _on_RegionEntry_pressed(region_node):
	if current_entry != null:
		current_entry.region.modulate.a = 0.5
	
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
		current_entry.region.modulate.a = 1


func _on_Prompt_text_changed():
	if current_entry != null:
		current_entry.set_text(prompt.text)
		current_entry.region.data[RegionArea2D.DESCRIPTION] = prompt.text
