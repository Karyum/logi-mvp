extends Node2D

func _draw():
	#for cell in $Ground.get_used_cells():
		#var world_pos = $Ground.map_to_local(cell) + Vector2(-56, 25)
		#draw_string(ThemeDB.fallback_font, world_pos, str(cell.x, ",", cell.y), HORIZONTAL_ALIGNMENT_CENTER, -1, 64)

	for cell in $Ground.get_used_cells():
		var world_pos = $Ground.map_to_local(cell)
		draw_string(ThemeDB.fallback_font, world_pos, str(cell.x, ",", cell.y), HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
