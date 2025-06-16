extends Node2D

@onready var camera: Camera2D = $Node2D/Camera2D

func _ready() -> void:
	var player_territory: Array[Vector2i] = []
	#var camera_rotation: int = 0
	var starting_position: Vector2i = Vector2i.ZERO
	
	var map_scene = GameState.map.map_scene.instantiate()
	$Map.add_child(map_scene)
	
	camera.change_default_zoom(GameState.map.max_zoom, GameState.map.min_zoom)
	
	for key: Vector2i in TerritoryManager.territories.keys():
		if TerritoryManager.territories[key] == NetworkManager.player_id:
			player_territory.append(key)
		
			#if GameState.map.camera_rotation.has(key):
				#camera_rotation = GameState.map.camera_rotation[key]

			if GameState.map.starting_positions.has(key):
				starting_position = key

	var hex_global_position = map_scene.map_to_local(starting_position)
	map_scene.build_territory(player_territory)
	
	#camera.rotate(deg_to_rad(camera_rotation))
	camera.move_to_position(hex_global_position)
	
