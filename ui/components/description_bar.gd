extends Panel

const TEXT_PREFIX = "  > "

onready var label = $Margin/Label
onready var menu = $Margin/Menu
onready var hover_indicator = $HoverIndicator

var minimal_indexes = [
	Consts.UI_CONTROL_RIGHT_CLICK,
	Consts.UI_CONTROL_LEFT_CLICK,
	Consts.UI_CONTROL_MIDDLE_CLICK,
	Consts.UI_CONTROL_SCROLL_UP,
	Consts.UI_CONTROL_SCROLL_DOWN,
]
var pressed_left = false
var pressed_right = false

var added_descriptions: Dictionary = {}
var text: String = ''
var format_array: Array = []

func _ready():
	Roles.request_role(self, Consts.ROLE_DESCRIPTION_BAR)
	var error = UIOrganizer.connect("locale_changed", self, "update_tr_descriptions")
	l.error(error, l.CONNECTION_FAILED)
	update_text()
	Tutorials.subscribe(self, Tutorials.TUT2)
	hover_indicator.visible = false


func _tutorial(tutorial_seq: TutorialSequence):
	tutorial_seq.add_tr_named_step(Tutorials.TUT2_MOVE_EDIT_GENERATION, [label])


func set_text(cue: Cue):
	# [ text, string_{0}, string_{1}, ... ]
	text = cue.str_at(0, '', false)
	var format = cue._arguments.duplicate()
	format.pop_front()
	format_array = format
	update_text()


func update_text():
	label.hint_tooltip = tr(text).format(format_array)
	label.text = TEXT_PREFIX + label.hint_tooltip


func update_tr_descriptions(_locale = null):
	var text_value: String
	var description: String
	update_text()
	for title_key in added_descriptions.keys():
		text_value = added_descriptions[title_key]
		description = tr(title_key) + ": " + tr(text_value) # donetr
		menu.set_labeled_item(description, title_key, false)


func add(cue: Cue):
	# { title1: description1,
	#	title2: description2,
	#	... }
	for title_key in cue._options.keys():
		added_descriptions[title_key] = cue.str_option(title_key, '-')


func clear(_cue: Cue = null):
	# We don't clear the menu since it gets cleared everytime before it shows up
	text = ''
	update_text()


func hide(_cue: Cue = null):
	visible = false


func show(_cue: Cue = null):
	visible = true


func show_descriptions_popup():
	menu.clear()
	added_descriptions.clear()
	Cue.new(Consts.UI_HAS_DESCRIPTION_GROUP, "reload_description").execute()
	update_tr_descriptions()
	menu.popup_at_cursor()


func _on_ClickArea_gui_input(event):
	if not event is InputEventMouseButton:
		return
	
	# left click
	if event.get_button_index() == BUTTON_LEFT:
		if pressed_left and not event.pressed:
			show_descriptions_popup()
		
		pressed_left = event.pressed
	# right click
	elif event.get_button_index() == BUTTON_RIGHT:
		if pressed_right and not event.pressed:
			pass
		
		pressed_right = event.pressed


func _on_ClickArea_mouse_entered():
	hover_indicator.modulate = ThemeChanger.get_aux_accent_color()
	hover_indicator.visible = true


func _on_ClickArea_mouse_exited():
	hover_indicator.visible = false
