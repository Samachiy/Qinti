extends Control


onready var info_dialog = $InfoDialog
onready var confirm_dialog = $ConfirmationDialog
onready var loading_dialog = $LoadingDialog


func _ready():
	Roles.request_role(self, Consts.ROLE_DIALOGS)


func request_user_action(cue: Cue):
	# [ text, code_to_copy ]
	var text = cue.str_at(0, '')
	var code = cue.str_at(1, '', false)
	info_dialog.display_text(text, code)


func request_confirmation(cue: Cue):
	# [ text: String, object: Object, method: String, args: Array = [] ]
	var text = cue.str_at(0, '')
	var object = cue.object_at(1, null)
	var method = cue.str_at(2, '')
	var args = cue.array_at(3, [], false)
	confirm_dialog.request(text, object, method, args)


func request_load_message(cue: Cue):
	# [ text: String]
	var text = cue.str_at(0, '')
	loading_dialog.display_text(text)
