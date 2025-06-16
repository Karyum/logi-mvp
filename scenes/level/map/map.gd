@tool
extends Node2D

var _frontline_points: Array[Vector2] = []

var frontline_points:
	get:
		return _frontline_points
	set(value):
		_frontline_points = value
		queue_redraw()

func _draw():
	#for cell in $Ground.get_used_cells():
		#var world_pos = $Ground.map_to_local(cell) + Vector2(-56, 25)
		#draw_string(ThemeDB.fallback_font, world_pos, str(cell.x, ",", cell.y), HORIZONTAL_ALIGNMENT_CENTER, -1, 64)

	for cell in $Ground.get_used_cells():
		var world_pos = $Ground.map_to_local(cell)
		draw_string(ThemeDB.fallback_font, world_pos, str(cell.x, ",", cell.y), HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	
	#for point in frontline_points:
	draw_multiline(frontline_points, Color.CORNFLOWER_BLUE, 3)
