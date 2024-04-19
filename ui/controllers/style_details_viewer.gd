extends VBoxContainer

onready var is_negative_checkbox = $Viewer/Details/Negative
onready var strenght_slider = $Viewer/Details/Strenght
onready var extra_strenght_slider = $Viewer/Details/ExtraStrenght
onready var extra_prompt_positive = $Viewer/Details/Margin/Extra/PositivePrompt
onready var extra_prompt_negative = $Viewer/Details/Margin/Extra/NegativePrompt
onready var extra_prompt = $Viewer/Details/Margin/Extra
onready var image = $Viewer/Photo/Image
onready var image_frame = $Viewer/Photo
onready var description = $Viewer/Details/Description
onready var edit_controls = $EditControls
onready var edit_cancel = $EditControls/Cancel
onready var edit_save = $EditControls/Save
onready var default_save = $EditControls/SaveDefaults # same as edit sve, but different text

export(bool) var readonly_prompt = false
export(bool) var show_preview = true
export(bool) var show_description = true

var styling_data: StylingData = null
var new_image: ImageData = null

signal close_requested

func _ready():
	image_frame.visible = show_preview
#	if readonly_prompt:
#		extra_prompt_positive.readonly = readonly_prompt
#		extra_prompt_negative.readonly = readonly_prompt
#		extra_prompt_positive.mouse_filter = MOUSE_FILTER_IGNORE
#		extra_prompt_negative.mouse_filter = MOUSE_FILTER_IGNORE
#		edit_controls.visible = not readonly_prompt
	edit_cancel.visible = not readonly_prompt
	edit_save.visible = not readonly_prompt
	default_save.visible = readonly_prompt


func set_data(styling_data_: StylingData):
	styling_data = styling_data_
	is_negative_checkbox.pressed = styling_data.is_negative
	strenght_slider.set_value(styling_data.strenght_core)
	extra_strenght_slider.set_value(styling_data.strenght_extra)
	extra_prompt_positive.set_text(styling_data.positive_prompt_extra)
	extra_prompt_negative.set_text(styling_data.negative_prompt_extra)
	description.set_text(styling_data.description)
	new_image = null
	image.texture = styling_data.get_image_data().texture
	


func get_data_dictionary(_cue: Cue = null):
	var dict: Dictionary = {
		styling_data.IS_NEGATIVE_STYLE: is_negative_checkbox.pressed,
		styling_data.STRENGHT: strenght_slider.get_value(),
		styling_data.STRENGHT_EXTRA: extra_strenght_slider.get_value(),
		styling_data.POS_PROMTP_EXTRA: extra_prompt_positive.text,
		styling_data.NEG_PROMTP_EXTRA: extra_prompt_negative.text,
	}
	return dict


func set_data_dictionary(dictionary: Dictionary):
	is_negative_checkbox.pressed = dictionary.get(styling_data.IS_NEGATIVE_STYLE, false)
	strenght_slider.set_value(dictionary.get(styling_data.STRENGHT, 1.0))
	extra_strenght_slider.set_value(dictionary.get(styling_data.STRENGHT_EXTRA, 1.0))
	extra_prompt_positive.set_text(dictionary.get(styling_data.POS_PROMTP_EXTRA, ''))
	extra_prompt_negative.set_text(dictionary.get(styling_data.NEG_PROMTP_EXTRA, ''))


func save_data():
	styling_data.file_cluster.save_json(get_data_dictionary())
	
	if description.text.empty() and styling_data.file_cluster.description_file.empty():
		# if description is empty and there's no previous file, there's no point of writing
		# the description file for it will be just empty. It there was a previous file,
		# at the very list we could be erasing the data clean, but there isn't
		pass
	else:
		styling_data.file_cluster.save_text(description.text)
	
	if new_image != null:
		styling_data.file_cluster.save_png(new_image)
		styling_data.refresh_image_data()
	
	styling_data.reload_data()


func refresh_image():
	var image_data = styling_data.get_image_data()
	if image_data is ImageData:
		image.texture = image_data.texture


func get_positive_prompt() -> String:
	return styling_data.get_positive_prompt_custom(
			strenght_slider.get_value(), 
			extra_strenght_slider.get_value(), 
			is_negative_checkbox.pressed,
			extra_prompt_positive.text
		)


func get_negative_prompt() -> String:
	return styling_data.get_negative_prompt_custom(
			strenght_slider.get_value(), 
			extra_strenght_slider.get_value(), 
			is_negative_checkbox.pressed,
			extra_prompt_negative.text
		)


func clear():
	description.text = ''
	is_negative_checkbox.pressed = false
	strenght_slider.set_value(1.0)
	extra_strenght_slider.set_value(1.0)
	extra_prompt_positive.text = ''
	extra_prompt_negative.text = ''


func _on_DropArea_modifier_dropped(_position, modifier):
	if modifier is Modifier:
		new_image = modifier.image_data
		image.texture = new_image.texture


func _on_Save_pressed():
	save_data()


func _on_Cancel_pressed():
	emit_signal("close_requested")
