extends Node


var modifiers_overlay
var gen_image_overlay
var gen_mask_overlay
var underlay
var overlay_image: Image = null
var underlay_image: Image = null

var registry: Dictionary = {}

func set_lay(texture_node: Node, size_control: Control, size_property: String, 
lay_id: String):
	if lay_id in registry:
		l.g("No lay was set, a lay with same id already exists. Lay id: " + lay_id)
		return
		
	var lay = Lay.new(texture_node, size_control, size_property)
	registry[lay_id] = lay


func append(id: String, image: Image):
	var lay = registry.get(id, null)
	if lay is Lay:
		lay.append(image)
	else:
		l.g("No lay was found, no image was appended. Lay id: " + id)


func refresh(id: String, material):
	var lay = registry.get(id, null)
	if lay is Lay:
		lay.update(material)
	else:
		l.g("No lay was found, no image was refreshed. Lay id: " + id)


func clear(id: String):
	var lay = registry.get(id, null)
	if lay is Lay:
		lay.clear()
	else:
		l.g("No lay was found, no image was cleared. Lay id: " + id)


func set_material(id: String, material):
	var lay = registry.get(id, null)
	if lay is Lay:
		lay.set_material(material)
	else:
		l.g("No lay was found, no material was set. Lay id: " + id)


func set_alpha(id: String, alpha: float):
	var lay = registry.get(id, null)
	if lay is Lay:
		lay.set_alpha(alpha)
	else:
		l.g("No lay was found, no alpha was set. Lay id: " + id)


func get_alpha(id: String) -> float:
	var lay = registry.get(id, null)
	if lay is Lay:
		return lay.get_alpha()
	else:
		l.g("No lay was found, can't retrieve alpha. Lay id: " + id)
		return 0.0


func set_visibility(id: String, visible: float):
	var lay = registry.get(id, null)
	if lay is Lay:
		lay.set_visibility(visible)
	else:
		l.g("No lay was found, no alpha was set. Lay id: " + id)


class Lay extends Reference:
	var image: Image = null
	var node: Node = null
	var rect_size_node: Control = null
	var rect_size_property: String = ''
	
	func _init(texture_node: Node, size_control: Control, size_property: String):
		node = texture_node
		rect_size_node = size_control
		rect_size_property = size_property
	
	
	func create_image(base_image: Image):
		var size = rect_size_node.get(rect_size_property)
		if size == null:
			l.g("Failure creating lay image, rect_size_property doesn't exist. " + 
					"Setting default size.")
			size = Vector2(100, 100)
		image = Image.new()
		image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		ImageProcessor.blend_images(image, base_image)
	
	
	func append(append_image: Image):
		if append_image == null:
			return
		
		if image == null:
			create_image(append_image)
		else:
			ImageProcessor.blend_images(image, append_image)
		pass
	
	
	func update(material):
		if image == null:
			node.texture = null
			return
		
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image)
		image_texture.flags = Texture.FLAG_FILTER
		node.texture = image_texture
		node.material = material
	
	
	func set_material(material):
		node.material = material
	
	
	func clear():
		node.texture = null
		node.material = null
		image = null
	
	
	func set_alpha(opacity: float):
		node.modulate.a = opacity
	
	
	func get_alpha():
		return node.modulate.a
	
	
	func set_visibility(visibility: bool):
		node.visible = visibility
