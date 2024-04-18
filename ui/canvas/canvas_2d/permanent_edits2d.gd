extends Sprite

onready var viewport = $Viewport
onready var offset_node = $Viewport/Offset

# The scrrenshot_sprite is to preserve on the viewport the changes made by
# deleted nodes
onready var scr_sprite = $Viewport/Offset/ScreenshotSprite



var image: Image
var prevs: Array = []
var new_node_offset_pos = Vector2.ZERO
var quality_loss_snapshot_offset = Vector2.ZERO
var pending_screenshot: bool = false
var refresh_texture_pending: bool = false


func _ready():
	texture = viewport.get_texture()
	texture.flags = Texture.FLAG_FILTER
	scr_sprite.visible = true


func set_size_as(size: Vector2):
	size = size / scale
	if size != viewport.size:
		viewport.size = size


func set_position_as(origin_position: Vector2, offset_position: Vector2):
	# The offset of new nodes
	new_node_offset_pos = (-origin_position + offset_position) / scale


func refresh_offset():
	# See comments in consolidate(), above the line "scr_sprite.offset = offset"
	# This two lineas are what makes the canvas briefly displace and go back 
	# into place when resizing canvas, hence why we set the modulate to 0 before
	# and restore it after
	var alpha = modulate.a8
	if alpha == 0:
		modulate.a8 = 1
	else:
		alpha = 255
		modulate.a8 = 0
	offset_node.position = new_node_offset_pos
	offset = -new_node_offset_pos
	modulate.a8 = alpha


func add_node(node: Node2D):
	offset_node.add_child(node)
	refresh_texture_pending = true
	
	# We do this to adjust the scale of the incoming node, since the root node 
	# of this scene is already scaled
	node.scale /= scale
	
	
	# Here we are managing what happens if the viewport was cleared and a new node
	# comes in. You see, if this node is invisible, that means we cleared it, and if
	# a new node comes, we need to display a screencapture with that node only, hence we
	# remove what was on the texture. The reason we don't remove the texture before is
	# in case an undo makes necessary to restore what was cleared
	if node.visible and modulate.a8 == 0:
		modulate.a8 = 1
		scr_sprite.texture = null
	
	pending_screenshot = true
	refresh_offset()


func consolidate():
	if not owner.is_visible_in_tree():
		return
	
	if offset_node.get_child_count() <= 1:
		return
	
	if pending_screenshot:
		pending_screenshot = false
	else:
		return
	
	# The top left corner of scr_sprite needs to line up with the 'Permanent' node
	# (0, 0) position, so after adding the offset, we set the position with the 
	# opposite value
	# We have to set the offset like that because if we resize the layer, we need to 
	# make the screenshot follow the current changes, an the easiest way to do so is 
	# by changing the position of the screenshot, whereas the offset will keep the
	# top left corner in the right place as it moves around.
	scr_sprite.offset = offset
	
	# taking the screenshot and placing it as texture
	image = viewport.get_texture().get_data()
	var image_texture = ImageTexture.new()
	image_texture.create_from_image(image)
	scr_sprite.texture = image_texture
	for node in offset_node.get_children():
		if node != scr_sprite:
			node.queue_free()
	
	scr_sprite.visible = true
	texture = viewport.get_texture()


func is_empty():
	if scr_sprite.texture == null or modulate.a8 == 0:
		return true
	else:
		return false
