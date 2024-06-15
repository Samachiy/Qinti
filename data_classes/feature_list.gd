extends Reference

class_name FeatureList

# All features wll be enabled by default, it's a duty of every api to disable lacking features


# UI filtering currently has the present characteristics:
# CONTROLNET
# - Modifier change button refills it's options (Modifier refill)
# - Hides add scribble option
# 	- If there's nothing add to the 'plus' modifier-area button, it hides too
# IMAGE INFO
# - Modifier change button refills it's options (Modifier refill)
# - On dropping image into modifiers area, changes to image_to_image rather than image_info
# IMAGE TO IMAGE
# - Modifier change button refills it's options (Modifier refill)
# - Hides quick drawing to ai image button and it's settings	
# - Hides main canvas right click option 
# - On droping image on modifiers area, do drops it but adds a warning icon 
# INPAINT OUTPAINT
# - Hides inpaint eraser and brush		
# - Hides outpaint button in modify gen area (and it's setting, if any)	
# - Hides main canvas right click option 


var features: Dictionary

signal features_changed

func connect_check_feature(feature_name: String, target_object: Object, check_method: String, 
uncheck_method: String):
	var feature = _get_feature(feature_name)
	feature.connect("feature_checked", target_object, check_method)
	feature.connect("feature_unchecked", target_object, uncheck_method)


func connect_toggle_feature(feature_name: String, target_object: Object, target_method: String):
	var feature = _get_feature(feature_name)
	feature.connect("feature_toggled", target_object, target_method)


func add_feature(feature_name: String):
# warning-ignore:return_value_discarded
	_get_feature(feature_name) # This creates it if it doesn't exist


func has_feature(feature_name: String) -> bool:
# warning-ignore:return_value_discarded
	var feature = _get_feature(feature_name, false)
	if feature is Feature:
		return feature.available
	else:
		return false




func check(feature_name: String):
	var feature = _get_feature(feature_name)
	if feature.check():
		emit_signal("features_changed")


func uncheck(feature_name: String):
	var feature = _get_feature(feature_name)
	if feature.uncheck():
		emit_signal("features_changed")


func reset(feature_name: String):
	var feature = _get_feature(feature_name)
	feature.reset()
	emit_signal("features_changed")


func reset_all():
	for feature in features.values():
		if feature is Feature:
			feature.reset()


func _get_feature(feature_name: String, create: bool = true) -> Feature:
	var result = features.get(feature_name, null)
	if result is Feature:
		return result
	elif create:
		result = Feature.new()
		features[feature_name] = result
		return result
	else:
		return null


class Feature extends Reference:
	
	var available: bool = true
	
	signal feature_checked
	signal feature_unchecked
	signal feature_toggled(enabled)
	
	func check() -> bool:
		var changed: bool = false
		if not available:
			changed = true
		
		available = true
		emit_signal("feature_checked")
		emit_signal("feature_toggled", true)
		return changed
	
	
	func uncheck() -> bool:
		var changed: bool = false
		if available:
			changed = true
		
		available = false
		emit_signal("feature_unchecked")
		emit_signal("feature_toggled", false)
		return changed
	
	
	func reset():
		# Since the default feature state is true (available) reset just sets it 
		# without emitting any signals
		available = true

