extends Reference

class_name ImageViewerRelay
# grabs different emitted signals and relays them only if the configuration matches

# warning-ignore:unused_signal
signal image_selected(index, image)
# warning-ignore:unused_signal
signal image_changed(index, image)
# warning-ignore:unused_signal
signal viewer_closed(index, image)

var connections: Dictionary = {}


func connect_relay(object: Object, method: String, on_selection: bool = false, 
on_change: bool = true, on_viewer_closed: bool = true):
	if object == null:
		l.g("Can't connect image viewer relay, object is null. Method is: " + method)
	
	var entry: RelayConnection = RelayConnection.new(
			self, on_selection, on_change, on_viewer_closed)
	
	entry.connect_relay(object, method)
	connections[object] = entry


func disconnect_relay(object: Object):
	var entry = connections.get(object, null)
	if entry is RelayConnection:
		entry.disconnect_relay()


class RelayConnection extends Reference:
	var emit_on_selection: bool
	var emit_on_change: bool
	var emit_on_viewer_closed: bool
	var method: String
	var object: Object = null
	var relay: ImageViewerRelay
	
	signal image_change_requested(index, image)
	
	func _init(relay_: ImageViewerRelay, on_selection: bool, 
	on_change: bool, on_viewer_closed: bool):
		emit_on_selection = on_selection
		emit_on_change = on_change
		emit_on_viewer_closed = on_viewer_closed
		relay = relay_
		
	
	func connect_relay(object_: Object, method_: String):
		var error = connect("image_change_requested", object_, method_)
		l.error(error, l.CONNECTION_FAILED)
		if error == OK:
			method = method_
			object = object_
		
		var e = relay.connect('image_selected', self, '_on_image_selected')
		l.error(e, l.CONNECTION_FAILED + " On specific image viewer relay")

		e = relay.connect('image_changed', self, '_on_image_changed')
		l.error(e, l.CONNECTION_FAILED + " On specific image viewer relay")

		e = relay.connect('viewer_closed', self, '_on_viewer_closed')
		l.error(e, l.CONNECTION_FAILED + " On specific image viewer relay")
	
	
	func disconnect_relay():
		call_deferred("free") 
	
	
	func _on_image_selected(index, image):
		if emit_on_selection:
			emit_signal("image_change_requested", index, image)
	
	
	func _on_image_changed(index, image):
		if emit_on_change:
			emit_signal("image_change_requested", index, image)
	
	
	func _on_viewer_closed(index, image):
		if emit_on_viewer_closed:
			emit_signal("image_change_requested", index, image)
