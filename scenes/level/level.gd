extends Node2D

@onready var camera: Camera2D = $Node2D/Camera2D
var player_territory: Array[Vector2i] = []

func _ready() -> void:
	var starting_position: Vector2i = Vector2i.ZERO
	var map_scene: MapController = GameState.map.map_scene.instantiate()
	
	$MapContainer.add_child(map_scene)
	
	camera.change_default_zoom(GameState.map.max_zoom, GameState.map.min_zoom)
	
	for key: Vector2i in TerritoryManager.territories.keys():
		if TerritoryManager.territories[key] == NetworkManager.player_id:
			player_territory.append(key)
		
			if GameState.map.starting_positions.has(key):
				starting_position = key

	var hex_global_position = MapManager.map.map_to_local(starting_position)
	map_scene.build_territory()
	ArmyManager.spawn_armies()
	TransportManager.setup_transport(GameState.map.trucks_amount)
	
	#camera.rotate(deg_to_rad(camera_rotation))
	camera.move_to_position(hex_global_position)
	
	
	
