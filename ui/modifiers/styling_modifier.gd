extends ModifierMode

const CONTROLLER_DATA = "controller"


var styling_data: StylingData = null
var controller_role = Consts.ROLE_CONTROL_STYLING
var prompt_cue: Cue = null
var is_hash_requested: bool = false
var q_hash = '' # used exclusively to load mode from file
var sha256_hash = '' # used exclusively to load mode from file


func select_mode():
	if selected:
		return
	
	selected = true
	if styling_data == null:
		add_warning_no_styling_data()
		Cue.new(controller_role, "open_board").args([self]).execute() 
		# RESUME open error board instead and load info
		return
	
	Cue.new(controller_role, "open_board").args([self]).execute()
	if data_cue == null:
		Cue.new(controller_role, "set_base_data").args([styling_data]).execute()
	else:
		data_cue.clone().execute()


func deselect_mode():
	selected = false
	data_cue = Cue.new(controller_role, "get_data_cue").execute()
	prompt_cue = Cue.new(controller_role, "get_prompt_cue").execute()


func prepare_mode():
	if is_hash_requested:
		return
	
	styling_data.file_cluster.solve_hash(false)


func apply_to_api(_api):
	if styling_data == null:
		return
	
	if selected:
		prompt_cue = Cue.new(controller_role, "get_prompt_cue").execute()
	elif prompt_cue == null:
		var dict: Array = [
			styling_data.get_positive_prompt(),
			styling_data.get_negative_prompt()
		]
		prompt_cue =  Cue.new(Consts.ROLE_API, "cue_add_to_prompt").args(dict)
	
	prompt_cue.clone().execute()


func clear_board():
	Cue.new(controller_role, "clear").execute()


func get_model_hash():
	if styling_data == null:
		return sha256_hash
	else:
		return styling_data.file_cluster.get_hash()


func get_model_q_hash():
	if styling_data == null:
		return q_hash
	else:
		return styling_data.file_cluster.get_q_hash()


func queue_hash_now():
	styling_data.file_cluster.solve_hash(true)


func get_mode_data():
	var disassembled_data_cue = []
	if data_cue is Cue:
		disassembled_data_cue = data_cue.disassemble()
		var clean_data_cue: Cue
		clean_data_cue = data_cue.clone()
		clean_data_cue._arguments.clear()
		disassembled_data_cue = clean_data_cue.disassemble()
	var data = {
		CONTROLLER_DATA: disassembled_data_cue,
		FileCluster.HASH: get_model_hash(),
		FileCluster.Q_HASH: get_model_q_hash(),
	}
	return data


func set_mode_data(data: Dictionary):
	var disassembled_data_cue = data.get(CONTROLLER_DATA, [])
	data_cue = Cue.new('', '').assemble(disassembled_data_cue, false)
	q_hash = data.get(FileCluster.Q_HASH, "")
	sha256_hash = data.get(FileCluster.HASH, "")
	retrieve_styling_data_q_hash(true)


func retrieve_styling_data_q_hash(connect_if_failure: bool):
	styling_data = Cue.new(
			Consts.ROLE_TOOLBOX, 
			"get_thumbnail_q_hash"
			).args([q_hash]).execute()
	
	# DEPRECATED code, keep just in case q_hash is not good enough and we need to \
	# change it to this method
#	var thumbnail = Cue.new(
#			Consts.ROLE_TOOLBOX, 
#			"get_style_thumbnails_by_q_hash"
#			).args([q_hash]).execute()
#
#	if thumbnails.size() > 1:
#		l.g("Two different file clusters have the same q_hash, choosign first. Error data: " + 
#			str(thumbnails))
#	elif thumbnails.size() == 0:
#		add_warning_no_styling_data()
#		pass
#
#	for thumbnail in thumbnails:
#		if thumbnail is StylingThumbnail:
#			styling_data = thumbnail.styling_data
	
	if styling_data == null:
		add_warning_no_styling_data()
		if not connect_if_failure:
			return
		
		var toolbox = Roles.get_node_by_role(Consts.ROLE_TOOLBOX)
		if toolbox is Control and toolbox.has_signal("file_clusters_refreshed"):
			toolbox.connect(
					"file_clusters_refreshed", 
					self, 
					"_on_toolbox_file_clusters_refreshed")
	else:
		# warning-ignore:return_value_discarded
		data_cue.args([styling_data])
	


func _on_toolbox_file_clusters_refreshed():
	retrieve_styling_data_q_hash(false)
	if styling_data != null:
		var toolbox = Roles.get_node_by_role(Consts.ROLE_TOOLBOX)
		if toolbox is Control and toolbox.has_signal("file_clusters_refreshed"):
			toolbox.disconnect(
					"file_clusters_refreshed", 
					self, 
					"_on_toolbox_file_clusters_refreshed")


func add_warning_no_styling_data():
	# RESUME add warning icon and on load, show the error board if clicked
	pass
	

