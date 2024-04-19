extends MarginContainer


# consts with the available messages, or maybe a dictionary
# Retrieve state using api (a dict -> message_text, progress
# Connect to start script function output

const BLINK_IN_TIME = 0.4
const BLINK_OUT_TIME = 0.8
const PROGRESS_KEY = "progress"
const PROGRESS_STATE_KEY = "state"
const PROGRESS_STATE_JOB_COUNT = "job_count"
const NO_LOG_AVAILABLE_1 = "NO_SERVER_LOG_AVAILABLE_1"
const NO_LOG_AVAILABLE_2 = "NO_SERVER_LOG_AVAILABLE_2"

onready var timer = $Timer
onready var loading_bar = $VBoxContainer/ReferenceRect/LoadingBar
onready var loading_frame = $VBoxContainer/ReferenceRect
onready var process_label = $VBoxContainer/HBoxContainer/AIProcessLabel
onready var normal_label = $VBoxContainer/HBoxContainer/Label
onready var server_console = $VBoxContainer/Consoles/SERVER_LOG
onready var program_console = $VBoxContainer/Consoles/PROGRAM_LOG
onready var cancel_button = $VBoxContainer/HBoxContainer/Cancel

var api_progress = "/sdapi/v1/progress?skip_current_image=true"
var progress_bar_blink: SceneTreeTween = null
var has_server_console_output: bool = false

func _ready():
	Roles.request_role(self, Consts.ROLE_SERVER_STATE_INDICATOR)
	server_console.visible = true
	var e = DiffusionServer.connect("state_changed", self, "_on_server_state_changed")
	l.error(e, l.CONNECTION_FAILED)
	Cue.new(Consts.ROLE_SERVER_MANAGER, "connect_server_output").args([
			self, "_on_server_output_received"]).execute()
	
	loading_frame.modulate.a8 = Consts.ACCENT_COLOR_A
	UIOrganizer.add_to_theme_by_modulate_group(loading_frame, Consts.THEME_MODULATE_GROUP_STYLE)
	loading_bar.modulate.a8 = Consts.ACCENT_COLOR_AUX1_A
	UIOrganizer.add_to_theme_by_modulate_group(loading_bar, Consts.THEME_MODULATE_GROUP_STYLE)


func _on_server_state_changed(_prev_state: String, new_state: String):
	cancel_button.visible = false
	if new_state == Consts.SERVER_STATE_READY:
		stop_loading_bar_blink()
		timer.stop()
		Cue.new(Consts.UI_AI_PROCESS_ONGOING_GROUP, "stop_animation").execute()
		process_label.visible = false
		if server_console.text.empty():
			server_console.text = tr(NO_LOG_AVAILABLE_1) + '\n' + tr(NO_LOG_AVAILABLE_2)
	else:
		timer.start()
		Cue.new(Consts.UI_AI_PROCESS_ONGOING_GROUP, "start_animation").execute()
		process_label.visible = true
		if new_state == Consts.SERVER_STATE_STARTING:
			start_loading_bar_blink()
		elif new_state == Consts.SERVER_STATE_GENERATING:
			cancel_button.visible = true
		elif new_state == Consts.SERVER_STATE_DOWNLOADING:
			cancel_button.visible = true
		
	normal_label.text = new_state


func start_loading_bar_blink():
	if progress_bar_blink != null:
		progress_bar_blink.kill()
	
	progress_bar_blink = create_tween().bind_node(self).set_loops()
# warning-ignore:return_value_discarded
	progress_bar_blink.tween_property(loading_bar, "modulate:a", 0.0, BLINK_OUT_TIME)
# warning-ignore:return_value_discarded
	progress_bar_blink.tween_property(loading_bar, "modulate:a", 1.0, BLINK_IN_TIME)
	

func stop_loading_bar_blink():
	if progress_bar_blink != null:
		progress_bar_blink.kill()
		progress_bar_blink = create_tween().bind_node(self)
# warning-ignore:return_value_discarded
		progress_bar_blink.tween_property(loading_bar, "modulate:a", 1.0, BLINK_IN_TIME)


#func cue_state_progress_checker(cue: Cue):
#	# [ server_address ]
#	var address = cue.str_at(0, '')
#	if not address.empty():
#		timer.start()



func set_progress(percentage: float):
	loading_bar.split_offset = int(loading_bar.rect_size.x * percentage)


func update_progress():
	match DiffusionServer.get_state():
		Consts.SERVER_STATE_GENERATING:
			DiffusionServer.request_progress(self, "_on_progress_retrieved")
		Consts.SERVER_STATE_DOWNLOADING:
			set_progress(DiffusionServer.downloader.get_progress())
		Consts.SERVER_STATE_READY:
			set_progress(1.0)
		Consts.SERVER_STATE_STARTING:
			set_progress(1.0)
		_:
			set_progress(0.0)


func _on_progress_retrieved(result):
	if not result is Dictionary:
		return
	
	set_progress(result.get(PROGRESS_KEY, 0.0))
	if DiffusionServer.get_state() == Consts.SERVER_STATE_GENERATING :
		if not has_job_count(result):
			# We change from GENERATING state to READY state here in case the generation  
			# was canceled because:
			# If the generation was successfully canceled server side, there will be no  
			# way of knowing that, but if the progress shows that nothing it's being  
			# done, it will change the state to READY
			DiffusionServer.set_state(Consts.SERVER_STATE_READY)


func _on_Timer_timeout():
	update_progress()


func _on_server_output_received(text):
	if not has_server_console_output:
		# This is to remove default messages when we add our first console output
		server_console.text = ''
		has_server_console_output = true
	
	server_console.text += text + "\n"



func show(_cue: Cue = null):
	var parent = get_parent()
	if parent is WindowDialog:
		parent.popup_centered_ratio(0.7)


func hide(_cue: Cue = null):
	var parent = get_parent()
	if parent is WindowDialog:
		parent.hide()


func cancel(_cue: Cue = null):
	match DiffusionServer.get_state():
		Consts.SERVER_STATE_GENERATING:
			DiffusionServer.cancel_diffusion()
		Consts.SERVER_STATE_DOWNLOADING:
			DiffusionServer.cancel_download()
		Consts.SERVER_STATE_READY:
			pass # Do nothing in this server_state
		Consts.SERVER_STATE_STARTING:
			pass # Do nothing in this server_state


func _on_Cancel_pressed():
	cancel()


func has_job_count(results: Dictionary, only_zero_is_false: bool = true):
	var state = results.get(PROGRESS_STATE_KEY, {})
	var job_count = null
	if state is Dictionary:
		job_count = state.get(PROGRESS_STATE_JOB_COUNT, null)
	
	if job_count == null:
		l.g("Failure to retrieve job count on server_state_indicator.gd. Data: " + 
				str(results))
		job_count = 0
	
	if only_zero_is_false:
		return int(job_count) != 0
	else:
		return job_count > 0



func _on_Consoles_tab_changed(_tab):
	if program_console.visible:
		program_console.text = l.get_content()


func get_server_output(_cue: Cue = null):
	return server_console.text
