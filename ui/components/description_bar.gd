extends Panel

const TEXT_PREFIX = "  > "
const LASTEST_VERSION_API = "https://api.github.com/repos/Samachiy/Qinti/releases/latest"
const LASTEST_VERSION_URL = "https://www.github.com/Samachiy/Qinti/releases/latest"
const LATEST_VER_KEY = "tag_name"

onready var label = $HBox/NotificationArea/Margin/Label
onready var menu = $HBox/NotificationArea/Margin/Menu
onready var hover_indicator = $HBox/NotificationArea/HoverIndicator
onready var update_button = $HBox/UpdateQinti

var minimal_indexes = [
	Consts.UI_CONTROL_LEFT_CLICK,
	Consts.UI_CONTROL_RIGHT_CLICK,
	Consts.UI_CONTROL_MIDDLE_CLICK,
	Consts.UI_CONTROL_SCROLL_UP,
	Consts.UI_CONTROL_SCROLL_DOWN,
]
var pressed_left = false
var pressed_right = false

var added_descriptions: Dictionary = {} #{ title1: description1, title2: description2, ...}

var descriptions_priority: Dictionary = {} # { priority1: [ title, ...], priority2: [ title, ...] 
var text: String = ''
var format_array: Array = []

func _ready():
	Roles.request_role(self, Consts.ROLE_DESCRIPTION_BAR)
	var error = UIOrganizer.connect("locale_changed", self, "update_tr_descriptions")
	l.error(error, l.CONNECTION_FAILED)
	update_text()
	Tutorials.subscribe(self, Tutorials.TUT2)
	hover_indicator.visible = false
	if OS.has_feature("standalone"):
		check_qinti_update()


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
	var priorities = descriptions_priority.keys()
	priorities.sort()
	var titles
	for priority in priorities:
		titles = descriptions_priority.get(priority, [])
		for title_key in titles:
			text_value = added_descriptions[title_key]
			description = tr(title_key) + ": " + tr(text_value) # donetr
			menu.set_labeled_item(description, title_key, false)


func add(cue: Cue):
	# [ priority: int == 100 ]
	# { title1: description1,
	#	title2: description2,
	#	... }
	var priority = cue.int_at(0, 100, false)
	var array: Array
	for title_key in cue._options.keys():
		added_descriptions[title_key] = cue.str_option(title_key, '-')
		array = descriptions_priority.get(priority, [])
		if array.empty():
			descriptions_priority[priority] = array

		array.append(title_key)


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
	descriptions_priority.clear()
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


func check_qinti_update():
	var api_request = APIRequest.new(self, "_on_latest_version_checked", self)
	api_request.api_get(LASTEST_VERSION_API)


func _on_latest_version_checked(result):
	var version_name
	if result is Dictionary:
		version_name = result.get(LATEST_VER_KEY)
	
	if not version_name is String:
		l.g("Latest version name on Github is not a string")
		return
	
	var ver_array: Array = version_name.split(".", false)
	# Example: 0.1.0-rc.1 will result in [0, 1, 0, 1]
	for i in range(ver_array.size()):
		ver_array[i] = int(ver_array[i])
	
	if ver_array.size() < 3:
		l.g("Latest version name on Github has an incorrect format: " + version_name)
		return
	elif ver_array.size() == 3:
		ver_array.append(0) # 0 means not a release candidate
	
	var current_is_rc = Director.release_candidate != 0
	var online_is_rc = ver_array[3] != 0
	var ver_cue = Cue.new('', '')
	var comparison = ver_cue._compare_version_to_array(ver_array)
	var has_update: bool
	if comparison == -1:
		has_update = true
	elif comparison == 0:
		if current_is_rc:
			has_update = not online_is_rc or ver_array[3] > Director.release_candidate
		else:
			has_update = false
	else:
		has_update = false
	
	update_button.visible = has_update
	if has_update:
		rect_min_size.x = 28
	return [comparison, has_update]


func _on_UpdateQinti_pressed():
	var error = OS.shell_open(LASTEST_VERSION_URL)
	l.error(error, "Failure to open lateste version webpage")






# Versioning check testing
# Place on _ready() if test is needed

#	var test = {}
#	test[LATEST_VER_KEY] = "0.1.0-rc.1"
#	print(test, _on_latest_version_checked(test))
#	test[LATEST_VER_KEY] = "0.1.1-rc.1"
#	print(test, _on_latest_version_checked(test))
#	test[LATEST_VER_KEY] = "0.1.0-rc.2"
#	print(test, _on_latest_version_checked(test))
#	test[LATEST_VER_KEY] = "0.1.0"
#	print(test, _on_latest_version_checked(test))
#	test[LATEST_VER_KEY] = "0.1.1"
#	print(test, _on_latest_version_checked(test))
#	test[LATEST_VER_KEY] = "0.0.0"
#	print(test, _on_latest_version_checked(test))
