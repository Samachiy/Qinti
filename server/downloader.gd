extends Node

const CONTROLNET_MODEL_EXT = '.pth'
const CONTROLNET_MODEL_CONFIG_EXT = ".yaml"

var current_download_request: APIRequest = null
var current_download_file_path: String = ''
var current_link: String = ''
var queue: Array = [] # [ cue, ... ]  we use cues since it's easy to extract info
var is_downloading: bool = false
var links_in_progress: Dictionary = {} # to check what is already queued for download

signal downloads_finished

var controlnet_links_old: Dictionary = {
	Consts.CN_TYPE_SHUFFLE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11e_sd15_shuffle",
	Consts.CN_TYPE_TILE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11f1e_sd15_tile",
	Consts.CN_TYPE_DEPTH: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11f1p_sd15_depth",
	Consts.CN_TYPE_CANNY: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_canny",
	Consts.CN_TYPE_INPAINT: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_inpaint",
	Consts.CN_TYPE_LINEART: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_lineart",
	Consts.CN_TYPE_MLSD: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_mlsd",
	Consts.CN_TYPE_NORMAL: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_normalbae",
	Consts.CN_TYPE_OPENPOSE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_openpose",
	Consts.CN_TYPE_SCRIBBLE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_scribble",
	Consts.CN_TYPE_SEG: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_seg",
	Consts.CN_TYPE_SOFTEDGE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_softedge",
	Consts.CN_TYPE_IP2P: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11e_sd15_ip2p",
}

var controlnet_links_t2i: Dictionary = {
	Consts.CN_TYPE_SHUFFLE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11e_sd15_shuffle",
	Consts.CN_TYPE_TILE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11f1e_sd15_tile",
	Consts.CN_TYPE_DEPTH: "https://huggingface.co/TencentARC/T2I-Adapter/resolve/main/models/" + \
		"coadapter-depth-sd15v1",
	Consts.CN_TYPE_CANNY: "https://huggingface.co/TencentARC/T2I-Adapter/resolve/main/models/" + \
		"coadapter-canny-sd15v1",
	Consts.CN_TYPE_INPAINT: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_inpaint",
	Consts.CN_TYPE_LINEART: "https://huggingface.co/TencentARC/T2I-Adapter/resolve/main/models/" + \
		"coadapter-sketch-sd15v1",
	Consts.CN_TYPE_MLSD: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_mlsd",
	Consts.CN_TYPE_NORMAL: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_normalbae",
	Consts.CN_TYPE_OPENPOSE: "https://huggingface.co/TencentARC/T2I-Adapter/resolve/main/models/" + \
		"t2iadapter_openpose_sd14v1",
	Consts.CN_TYPE_SCRIBBLE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_scribble",
	Consts.CN_TYPE_SEG: "https://huggingface.co/TencentARC/T2I-Adapter/resolve/main/models/" + \
		"t2iadapter_seg_sd14v1",
	Consts.CN_TYPE_SOFTEDGE: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11p_sd15_softedge",
	Consts.CN_TYPE_IP2P: "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/" + \
		"control_v11e_sd15_ip2p",
	Consts.CN_TYPE_COLOR: "https://huggingface.co/TencentARC/T2I-Adapter/resolve/main/models/" + \
		"t2iadapter_color_sd14v1", # Reference color
#	Consts.CN_TYPE_STYLE: "https://huggingface.co/TencentARC/T2I-Adapter/resolve/main/models/" + \
#		"t2iadapter_style_sd14v1", # Canceled, use reference only insterad
}


func search_controlnet_model(search_string: String):
	for model_link in controlnet_links_t2i.values():
		if search_string in model_link:
			return model_link.get_file()
	
	return controlnet_links_t2i.get(search_string, '').get_file()


func download_control_net(type_name):
	var link: String = controlnet_links_t2i.get(type_name, '')
	
	if link.empty():
		l.g("Couldn't download item of name '" + type_name + "', definition wasn't found")
		return
	
	var file_name = link.get_file()
	if not type_name in file_name:
		file_name = link.get_file() + type_name # This is done because we use the type name to find out
		# if it's the correct file
	
	var path = DiffusionServer.api.get_controlnet_dir()
	_queue_download(link + CONTROLNET_MODEL_EXT, path, file_name + CONTROLNET_MODEL_EXT)
	
	# Controlnets from lllyasviel/ControlNet-v1-1 also need a configuration file
	if "lllyasviel" in link:
		_queue_download(link + CONTROLNET_MODEL_CONFIG_EXT, path, file_name + CONTROLNET_MODEL_CONFIG_EXT)
	
	_http_request_completed('') # This function resets data and starts downloading the queue


func _queue_download(full_link: String, path: String, file_name: String):
	if full_link in links_in_progress:
		l.g("Link '" + full_link + "' is already queued, sipping link", l.INFO)
		return
	
	if file_name.empty():
		file_name = full_link.get_file()
	
	links_in_progress[full_link] = true
	queue.append(Cue.new("", "").args([
			full_link, 
			path, 
			file_name
	]))
	


func download(link: String, path: String, file_name: String = ''):
	if current_download_request != null:
		l.g("Couldn't download link '" + link + "', downloader is busy")
	
	var api_request = APIRequest.new(self, '_http_request_completed', self)
	api_request.connect_on_request_failed(self, '_http_request_failed')
	
	
	var dir = Directory.new()
	dir.make_dir_recursive(path)
	current_download_request = api_request
	current_download_file_path = path.plus_file(file_name)
	current_link = link
	if file_name.empty():
		file_name = link.get_file()
	
	l.g("Downloading from link: " + link, l.INFO)
	
	# The next code notifies the server_state_indicator for a state change 
	DiffusionServer.set_state(Consts.SERVER_STATE_DOWNLOADING)
	
	is_downloading = true
	api_request.download(link, path, file_name)


func download_cue(cue: Cue):
	# [ link, path, file_name ]
	var link = cue.str_at(0, '')
	var path = cue.str_at(1, '')
	var file_name = cue.str_at(2, '')
	download(link, path, file_name)


func _http_request_completed(_result):
# warning-ignore:return_value_discarded
	links_in_progress.erase(current_link)
	current_download_request = null
	current_download_file_path = ''
	current_link = ''
	if queue.empty():
		if is_downloading:
			DiffusionServer.set_state(Consts.SERVER_STATE_READY)
		
		is_downloading = false
		emit_signal("downloads_finished")
	else:
		var next = queue.pop_front()
		if next is Cue:
			download_cue(next)


func _http_request_failed(_response_code):
# warning-ignore:return_value_discarded
	links_in_progress.erase(current_link)
	l.g("Failure to donwload file: " + current_download_file_path)
	_http_request_completed('') # To clear data and proceed with next download, if any


func get_progress() -> float:
	if current_download_request == null:
		return -1.0
	
	var request: HTTPRequest = current_download_request.api_node
	var total_bytes: float = request.get_body_size()
	var downloaded_bytes: float = request.get_downloaded_bytes()
	if total_bytes == 0:
		return -1.0
	
	return downloaded_bytes / total_bytes


func cancel_download():
	if current_download_request is APIRequest:
		var file_path = current_download_request.downloading_full_file
		if not file_path.empty():
			var e = Directory.new().remove(file_path)
			l.error(e, "Failure to delete canceled download file: " + file_path )
		
		current_download_request.cancel()
		_http_request_completed('') # To clear data and proceed with next download, if any
		DiffusionServer.set_state(Consts.SERVER_STATE_READY)


func cancel_all_downloads():
	queue.clear()
	cancel_download()


