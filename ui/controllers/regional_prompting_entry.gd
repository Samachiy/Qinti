extends HBoxContainer

onready var enabled = $Enabled
onready var label = $Label

var region: RegionArea2D = null

signal display_info_requested(region_node)


func set_info(region_node: RegionArea2D, text: String):
	region = region_node
	label.text = text
	enabled.pressed = region_node.visible


func set_text(text: String):
	label.text = text


func _on_Enabled_toggled(button_pressed):
	if region is RegionArea2D:
		region.visible = button_pressed


func _on_Label_pressed():
	emit_signal("display_info_requested", region)
