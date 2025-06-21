@tool
extends Node2D
class_name MapController

var _frontline_points: Dictionary = {}

var frontline_points:
	get:
		return _frontline_points
	set(value):
		_frontline_points = value
		queue_redraw()

func build_territory():
	var new_frontline_points = HexUtil.get_front_line_points()
	frontline_points = new_frontline_points
	
func _ready() -> void:
	if Engine.is_editor_hint():
		# We are in the editor, so skip this code
		return
		
	MapManager.set_map_controller(self)

func _draw():
	#for cell in $Ground.get_used_cells():
		#var world_pos = $Ground.map_to_local(cell) + Vector2(-56, 25)
		#draw_string(ThemeDB.fallback_font, world_pos, str(cell.x, ",", cell.y), HORIZONTAL_ALIGNMENT_CENTER, -1, 64)

	for cell in $Ground.get_used_cells():
		var world_pos = $Ground.map_to_local(cell)
		draw_string(ThemeDB.fallback_font, world_pos, str(cell.x, ",", cell.y), HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
	
	# for point in frontline_points:
	if not frontline_points.is_empty():
		for player_id in frontline_points.keys():
			if not frontline_points[player_id].is_empty():
				draw_multiline(frontline_points[player_id], GameState.players[player_id].color, 3)
