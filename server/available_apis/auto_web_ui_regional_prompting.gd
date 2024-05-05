extends DiffusionAPIModule

var colors = []
#var colors = [
#	Color().from_hsv(0, 0.5, 0.5),
#	Color().from_hsv(0.5, 0.5, 0.5),
#	Color().from_hsv(0.25, 0.5, 0.5),
#	Color().from_hsv(0.75, 0.5, 0.5),
#	Color().from_hsv(0.125, 0.5, 0.5),
#	Color().from_hsv(0.375, 0.5, 0.5),
#	Color().from_hsv(0.625, 0.5, 0.5),
#	Color().from_hsv(0.875, 0.5, 0.5),
#]


func bake_regions():
	# regions_to_bake: Array = [] # [ [rect2_1, data_dict1], [rect2_2, data_dict2], ... ]
	for i in range(api.regions_to_bake.size(), -1, -1):
		# Iterate from bottom to top
		pass


func generate_colors(amount: int):
	var colors_dict = {} # { h1: Color(h, s, v)1, h2: Color(h, s, v)2, ... }
	var step_size = 0.5
	var h = 0
	while colors_dict.size() < amount:
		if not colors_dict.has(h):
			colors_dict[h] = Color().from_hsv(h, 0.5, 0.5)
		
		h += step_size
		if h >= 1.0:
			step_size = step_size / 2
			h = step_size
		
		if step_size <= 0.3:
			break
	
	return colors_dict.values()
