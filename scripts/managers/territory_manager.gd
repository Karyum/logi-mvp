extends Node

var aluminium_factory: PackedScene = preload("res://scenes/buildings/aluminium_factory.tscn")
var bio_factory: PackedScene = preload("res://scenes/buildings/bio_factory.tscn")
var steel_factory: PackedScene = preload("res://scenes/buildings/steel_factory.tscn")
@onready var tree = get_tree()

signal factory_placed(player_id: int, hex_pos: Vector2)
signal territory_data_loaded(player_id: int)

#var starting_positions: Array[Vector2] = [Vector2(2, 2), Vector2(23, 21)]
var territories: Dictionary = {}  # hex_pos -> player_id (who controls this hex)
var starting_position: Vector2i = Vector2i.ZERO

func _ready() -> void:
	GameState.game_battle_turn_started.connect(_on_game_battle_turn)

# Place factory - called locally, then synced
func place_factory_local(hex_pos: Vector2, buildingType: String):
	if not can_place_factory(hex_pos):
		print("Cannot place factory at ", hex_pos)
		return false
	
	# Call RPC to place factory across all clients
	place_factory_rpc.rpc(NetworkManager.player_id, buildingType, hex_pos)
	return true

# Check if player can place factory at this position
func can_place_factory(_hex_pos: Vector2) -> bool:
	# Factory already exists
	#if ProductionManager.has_factory_at(hex_pos):
		#return false
	
	# Player doesn't control this territory
	#if not territories.has(hex_pos) or territories[hex_pos] != NetworkManager.player_id:
		#return false
	
	return true

@rpc("any_peer", "call_local", "reliable")
func place_factory_rpc(placing_player_id: int, factory_type: String, hex_pos: Vector2):
	var factory_data = {
		"owner_id": placing_player_id,
		"position": hex_pos,
		"type": factory_type,
		"created_at": Time.get_unix_time_from_system(),
	}
	
	var buildings_parent = tree.current_scene.get_node("Buildings")
	var factory = null
	var global_hex_pos = MapManager.map.map_to_local(hex_pos)
		
	if factory_type == 'steel':
		factory = steel_factory.instantiate() as Node2D
		factory.position = global_hex_pos
		pass
	elif factory_type == 'aluminium':
		factory = aluminium_factory.instantiate() as Node2D
		factory.position = global_hex_pos
	elif factory_type == 'bio':
		factory = bio_factory.instantiate() as Node2D
		factory.position = global_hex_pos
		
	buildings_parent.add_child(factory)
	
	# Add factory to production manager
	ProductionManager.add_factory(hex_pos, factory_data)
	
	# Expand territory around new factory (optional game rule)
	#expand_territory_around_factory(hex_pos, placing_player_id, 1)
	
	factory_placed.emit(placing_player_id, hex_pos)
	print("Factory placed by player ", placing_player_id, " at ", hex_pos)

# Assign starting territory to a player
func assign_starting_territory():
	var map_territories: Array[TerritoryResource] = GameState.map.territories_hexes.duplicate()
	var players_ids = GameState.players.keys().duplicate()
	var starting_positions = GameState.map.starting_positions.duplicate()

	# Claim starting territory
	for player_id in players_ids:
		var index = randi() % starting_positions.size()
		var player_start_position = starting_positions[index]
		starting_positions.remove_at(index)
		territories[player_start_position] = player_id

		if not NetworkManager.is_host:
			sync_starting_position_rpc.rpc_id(player_id, player_start_position)
		else:
			starting_position = player_start_position
		
		for hex_pos in map_territories[index].territory_hexes:
			territories[hex_pos] = player_id
		
		map_territories.remove_at(index)
	
	# Sync territory changes to all clients
	sync_starting_territory_rpc.rpc(territories)
	if NetworkManager.is_host:
		territory_data_loaded.emit(NetworkManager.player_id)


func _on_game_battle_turn():
	pass
	#var next_hex = HexUtil.get_next_hex()
	#territories[next_hex] = NetworkManager.player_id
	#MapManager.map_controller.build_territory()
	#
	#capture_hex(next_hex)

func capture_hex(pos: Vector2i):
	territories[pos] = NetworkManager.player_id
	MapManager.map_controller.build_territory()
	capture_hex_rpc.rpc(pos, NetworkManager.player_id)

		
# NETWORK
# RPC to sync territory changes
@rpc("authority", "call_remote", "reliable")
func sync_starting_territory_rpc(new_territories: Dictionary):
	territories = new_territories
	territory_data_loaded.emit(NetworkManager.player_id)
	NetworkManager.loading_screen_part_loaded_rpc.rpc('territory_data', NetworkManager.player_id)
	
	
@rpc("authority", "call_remote", "reliable")
func sync_starting_position_rpc(new_starting_position: Vector2i):
	starting_position = new_starting_position
		
@rpc("any_peer", "call_remote", "reliable")
func capture_hex_rpc(hex_pos: Vector2i, player_id: int):
	territories[hex_pos] = player_id
	MapManager.map_controller.build_territory()
	
