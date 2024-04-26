extends Reference

class_name ServerAddress

var mirrors: Array = []
var url: String = ''
var counter: int = 0

func _init(server_urls: Array):
	
	for server_url in server_urls:
		if server_url is String:
			mirrors.append(server_url)
	
	if mirrors.empty():
		return null
	
	url = mirrors[0]
	return self


func reset_url_counter():
	counter = 0


func is_last_url():
	return counter == mirrors.size() - 1


func cycle_next_url():
	counter += 1
	if counter >= mirrors.size():
		counter = 0
	
	url = mirrors[counter]
