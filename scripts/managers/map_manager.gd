extends Node

var map: TileMapLayer = null
var map_controller = null

func set_map(new_tilemap: TileMapLayer) -> void:
	map = new_tilemap

func set_map_controller(new_controller: Node2D) -> void:
	map_controller = new_controller

func get_tile_id(pos: Vector2i):
	if map:
		return map.get_cell_source_id(pos)
	return -1
