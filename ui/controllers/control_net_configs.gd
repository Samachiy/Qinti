extends VBoxContainer

onready var controlnet_mode = $ControlnetMode
onready var weight = $Weight
onready var guidance_start = $GuidanceStart
onready var guidance_end = $GuidanceEnd

func _ready():
	controlnet_mode.add_labeled_item("CONTROLNET_MODE_BALANCED", 0)
	controlnet_mode.add_labeled_item("CONTROLNET_MODE_PROMPT_PRIORITY", 1)
	controlnet_mode.add_labeled_item("CONTROLNET_MODE_CONTROLNET_PRIORITY", 2)
	controlnet_mode.select_flag_value()


func get_controlnet_config(input_image: Image, default_values: bool = true) -> Cue:
	var contronlet_dic = {
		Consts.CN_INPUT_IMAGE: input_image,
	}
	# if default values is true, we just leve it at that, if true, ge gather all the values in 
	# the controller's controls and set them up in the dictionary
	if not default_values:
		contronlet_dic[Consts.CN_WEIGHT] = weight.get_value()
		contronlet_dic[Consts.CN_GUIDANCE_START] = guidance_start.get_value()
		contronlet_dic[Consts.CN_GUIDANCE_END] = guidance_end.get_value()
		contronlet_dic[Consts.CN_CONTROL_MODE] = controlnet_mode.get_selected()
	
	return contronlet_dic
