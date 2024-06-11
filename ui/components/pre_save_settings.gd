extends ConfirmationDialog

class_name SaveSettingsUI


const RECENT_IMG_AMOUNT = Consts.FLAG_SAVE_RECENT_IMG_AMOUNT


onready var recent_img_amount = $MarginContainer/RecentAmount


var call_object: Object = null
var call_method: String = ''
var call_path: String = ''
var last_settings = {}


func _ready():
	Roles.request_role(self, Consts.ROLE_SAVE_SETTINGS)


func request_settings(cue: Cue = null):
	# [ request_object: Object, request_method: String, path: String ]
	var request_object = cue.object_at(0, null)
	var request_method = cue.str_at(1, "")
	var path = cue.str_at(2, "")
	
	call_object = request_object
	call_method = request_method
	call_path = path
	
	popup_centered()


func get_settings(_cue: Cue = null):
	var config = {
		RECENT_IMG_AMOUNT: recent_img_amount.get_amount_label()
	}
	return config


func set_settings(cue: Cue):
	# Settings are in cue options
	recent_img_amount.set_amount_label(
			cue.int_option(RECENT_IMG_AMOUNT, recent_img_amount.get_amount_label())
	)


func get_last_settings(_cue: Cue = null):
	if last_settings.empty():
		return get_settings()
	else:
		return last_settings


func _on_SaveSettings_popup_hide():
	pass # Replace with function body.


func _on_SaveSettings_confirmed():
	if call_object == null or not is_instance_valid(call_object):
		l.g("Can't show save setting interface, not a valid object. Object: " + 
				str(call_object) + " Method: " + str(call_method))
		return
	
	if call_object.has_method(call_method):
		call_object.call(call_method, call_path, get_settings())
	else:
		l.g("Can't show save setting interface, not a valid method. Object: " + 
				str(call_object) + " Method: " + str(call_method))
		return
