extends ConfirmationDialog


var call_object: Object = null
var call_method: String = ''
var call_binds: Array = []
var is_busy: bool = false

func _ready():
	var e = connect("popup_hide", self, "_on_popup_hide")
	l.error(e, l.CONNECTION_FAILED)
	e = connect("confirmed", self, "_on_confirmed")
	l.error(e, l.CONNECTION_FAILED)


func _on_popup_hide():
	is_busy = false


func _on_confirmed():
	if not is_instance_valid(call_object):
		l.g("In server management, confirm dialog calling object is not a valid object: " + 
				str(call_object))
		return
	
	if call_object.has_method(call_method):
		call_object.callv(call_method, call_binds)
	else:
		l.g("In server management, confirm dialog calling object doesn't have the method: " 
				+ call_method)


func request(text: String, object: Object, method: String, args: Array = []):
	if is_busy:
		l.g("In server management, can't request confirm dialog, another request is in process")
		return
	
	if object == null:
		l.g("In server management, can't request confirm dialog, object is null")
		return
	
	if method.empty():
		l.g("In server management, can't request confirm dialog, method is empty")
		return
	
	is_busy = true
	call_object = object
	call_method = method
	call_binds = args
	dialog_text = text
	popup_centered()

