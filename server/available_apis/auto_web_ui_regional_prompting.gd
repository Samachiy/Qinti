extends DiffusionAPIModule

var colors = [
	Color().from_hsv(0, 0.5, 0.5),
	Color().from_hsv(0.5, 0.5, 0.5),
	Color().from_hsv(0.25, 0.5, 0.5),
	Color().from_hsv(0.75, 0.5, 0.5),
	Color().from_hsv(0.125, 0.5, 0.5),
	Color().from_hsv(0.375, 0.5, 0.5),
	Color().from_hsv(0.625, 0.5, 0.5),
	Color().from_hsv(0.875, 0.5, 0.5),
]


func bake_regions():
	# regions_to_bake: Array = [] # [ [rect2_1, data_dict1], [rect2_2, data_dict2], ... ]
	for i in range(api.regions_to_bake.size(), -1, -1):
		# Iterate from bottom to top
		pass
