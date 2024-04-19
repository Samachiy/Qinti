tool
extends Container

onready var ai_process_label = $ProcessButton/LoadIcon
onready var cancel_button = $Cancel

export(String) var text = '' setget set_text

signal pressed
signal animation_started
signal animation_ended

var is_processing: bool = false

func _ready():
	if not Engine.editor_hint:
		add_to_group(Consts.UI_AI_PROCESS_ONGOING_GROUP)
	set_text(text)


func set_text(value):
	text = value
	if Engine.editor_hint:
		$ProcessButton/LoadIcon.set_text(text)
	elif ai_process_label != null:
		cancel_button.visible = false
		ai_process_label.set_text(text)


func start_animation(_cue: Cue = null):
	ai_process_label.start_animation()


func stop_animation(_cue: Cue = null):
	ai_process_label.stop_animation()


func _on_AIProcessButton_pressed():
	if is_processing: 
		# we show the server process
		Cue.new(Consts.ROLE_SERVER_STATE_INDICATOR, "show").execute()
	else:
		# else, we emit signal so that anything that must happen, happens
		emit_signal("pressed")


func _on_Overlay_animation_started():
	var can_cancel = DiffusionServer.get_state() == DiffusionServer.STATE_GENERATING
	can_cancel = can_cancel or DiffusionServer.get_state() == DiffusionServer.STATE_DOWNLOADING
	if can_cancel:
		cancel_button.visible = true
	
	is_processing = true
	emit_signal("animation_started")


func _on_Overlay_animation_ended():
	cancel_button.visible = false
	is_processing = false
	emit_signal("animation_ended")


func _on_Cancel_pressed():
	Cue.new(Consts.ROLE_SERVER_STATE_INDICATOR, "cancel").execute()
	DiffusionServer.cancel_diffusion()
