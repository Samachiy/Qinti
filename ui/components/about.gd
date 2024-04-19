extends MarginContainer

const LICENSE_PATH = "res://LICENSE.txt"
const ABOUT_PATH = "res://ui/components/about.txt"

onready var license = $Tabs/LICENSE
onready var main_about = $Tabs/ABOUT
onready var tabs = $Tabs
onready var guion_label = $Tabs/SOFTWARE_USED/Guion/Name
onready var software_used = $Tabs/SOFTWARE_USED

var parent = null

func _ready():
	Roles.request_role(self, Consts.ROLE_ABOUT_WINDOW)
	parent = get_parent_control()
	if guion_label.text.empty():
		l.g("Missing a library/plugin acknowledgment")



func close(_cue: Cue = null):
	if parent is Control:
		parent.hide()


func open(_cue: Cue):
	if parent is WindowDialog:
		parent.popup_centered_ratio(0.5)


func _on_Tabs_tab_changed(_tab):
	match tabs.get_current_tab_control():
		license:
			if license.text.empty():
				license.text = get_license_text()
		main_about:
			if main_about.text.empty():
				main_about.text = get_main_about_text()
		software_used:
			if guion_label.text.empty():
				l.g("Missing a library/plugin acknowledgment")


func get_license_text():
	if not license.text.empty():
		return license.text
	
	var path = PCData.globalize_path(LICENSE_PATH)
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		var data = file.get_as_text()
		return data
	else:
		return ''


func get_main_about_text():
	if not main_about.text.empty():
		return main_about.text
	
	var path = PCData.globalize_path(ABOUT_PATH)
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		var data = file.get_as_text()
		return data
	else:
		return ''
