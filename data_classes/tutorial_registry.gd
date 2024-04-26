extends Node

var is_enabled: bool = true

var tutorial_test = Flag.new("tutorial test")
# Put your tutorials here


var _array = [
	tutorial_test
]


func reset():
	for tutorial in _array:
		if tutorial is Flag:
			tutorial.remove()


func available(tutorial_flag: Flag):
	if not is_enabled:
		return false
	
	if tutorial_flag.exists():
		return false
	else:
		return true
