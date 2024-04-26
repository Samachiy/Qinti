extends Reference

class_name FeatureList

# All features wll be enabled by default, it's a duty of every api to disable lacking features

var features: Dictionary

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
	feature.check()


func uncheck(feature_name: String):
	var feature = _get_feature(feature_name)
	feature.uncheck()


func reset(feature_name: String):
	var feature = _get_feature(feature_name)
	feature.reset()


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
	
	func check():
		available = true
		emit_signal("feature_checked")
		emit_signal("feature_toggled", true)
	
	func uncheck():
		available = false
		emit_signal("feature_unchecked")
		emit_signal("feature_toggled", false)
	
	func reset():
		# Since the default feature state is true (available) reset just sets it 
		# without emitting any signals
		available = true

