extends Reference

class_name StylingData

const IS_NEGATIVE_STYLE = "is_negative"
const STRENGHT = "strenght_core"
const POS_PROMTP_EXTRA = "positive_extra_prompt"
const NEG_PROMTP_EXTRA = "negative_extra_prompt"
const STRENGHT_EXTRA = "strenght_extra"

const LORA_FORMAT = "<lora:{0}:{1}>"
const LYCORIS_FORMAT = "<lyco:{0}:{1}>"
const TI_FORMAT = "({0}:{1})"
const NORMAL_TOKENS_FORMAT = "({0}:{1})"

const LORA_ID = 0
const LYCORIS_ID = 1
const TI_ID = 2
const NORMAL_TOKENS_ID = 3

var format: String
var file_cluster: FileCluster = null

# The following values are extracted from file_cluster after calling reload_data
# All of them can be left empty if there's no file cluster
var is_negative: bool = false 
var prompt_core: String = '' 
var strenght_core: float = 1.0 
var positive_prompt_extra: String = '' 
var negative_prompt_extra: String = '' 
var strenght_extra: float = 1.0
var description: String = '' # 

#signal style_preview_changed(image_data)

func _init(file_cluster_: FileCluster, format_: String):
	file_cluster = file_cluster_
	format = format_
	prompt_core = file_cluster.name
	reload_data()


func get_positive_prompt() -> String:
	return get_positive_prompt_custom(strenght_core, strenght_extra, is_negative)


func get_negative_prompt() -> String:
	return get_negative_prompt_custom(strenght_core, strenght_extra, is_negative)


func get_positive_prompt_custom(custom_strenght_core: float, custom_strenght_extra: float, 
negative: bool, extra_prompt: String = '') -> String:
	if extra_prompt.empty():
		extra_prompt = positive_prompt_extra
	
	var prompt = ''
	if not prompt_core.empty() and not negative:
		prompt += format.format([prompt_core, str(custom_strenght_core)])
	
	if not extra_prompt.empty():
		if not prompt.empty():
			prompt += ', '
		
		if custom_strenght_extra == 1.0:
			prompt += extra_prompt
		else:
			prompt += NORMAL_TOKENS_FORMAT.format([extra_prompt, str(custom_strenght_extra)])
	
	return prompt


func get_negative_prompt_custom(custom_strenght_core: float, custom_strenght_extra: float, 
negative: bool, extra_prompt: String = '') -> String:
	if extra_prompt.empty():
		extra_prompt = negative_prompt_extra
	
	var prompt = ''
	if not prompt_core.empty() and negative:
		prompt += format.format([prompt_core, str(custom_strenght_core)])
	
	if not extra_prompt.empty():
		if not prompt.empty():
			prompt += ', '
		
		if custom_strenght_extra == 1.0:
			prompt += extra_prompt
		else:
			prompt += NORMAL_TOKENS_FORMAT.format([extra_prompt, str(custom_strenght_extra)])
	
	return prompt


func get_image_data():
	return file_cluster.get_image_data()


func refresh_image_data():
	file_cluster.refresh_image_data()
#	emit_signal("style_preview_changed", get_image_data())


func reload_data():
	var saved_data: Dictionary = file_cluster.get_json_data()
	if not saved_data.empty():
		positive_prompt_extra = saved_data.get(POS_PROMTP_EXTRA, '')
		negative_prompt_extra = saved_data.get(NEG_PROMTP_EXTRA, '')
		is_negative = bool(saved_data.get(IS_NEGATIVE_STYLE, false))
		strenght_core = float(saved_data.get(STRENGHT, 1.0))
		strenght_extra = float(saved_data.get(STRENGHT_EXTRA, 1.0))
	
	description = file_cluster.get_txt_data()
