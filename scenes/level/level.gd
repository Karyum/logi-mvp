extends Node2D

@onready var tilemap: GroundTileMap = $Map/Ground
@onready var camera: Camera2D = $Node2D/Camera2D

func _ready() -> void:
	var player_terratory: Array[Vector2i] = []
	#var camera_rotation: int = 0
	var starting_position: Vector2i = Vector2i.ZERO
	
	camera.change_default_zoom(GameState.map.max_zoom, GameState.map.min_zoom)

	for key: Vector2i in TerritoryManager.territories.keys():
		if TerritoryManager.territories[key] == NetworkManager.player_id:
			player_terratory.append((key))
		
			#if GameState.map.camera_rotation.has(key):
				#camera_rotation = GameState.map.camera_rotation[key]

			if GameState.map.starting_positions.has(key):
				starting_position = key

	var hex_global_position = tilemap.map_to_local(starting_position)
	tilemap.build_terratory(player_terratory)
	
	#camera.rotate(deg_to_rad(camera_rotation))
	camera.move_to_position(hex_global_position)
	
