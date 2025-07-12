extends Node

@onready var tree = get_tree()

signal territory_data_loaded(player_id: int)

#var starting_positions: Array[Vector2] = [Vector2(2, 2), Vector2(23, 21)]
var territories: Dictionary[Vector2i, int] = {}  # hex_pos -> player_id (who controls this hex)
var starting_position: Vector2i = Vector2i.ZERO

func _ready() -> void:
	pass

# Check if player can place factory at this position
func can_place_factory(hex_pos: Vector2i, player_id: int) -> bool:
	# Factory already exists
	if ProductionManager.has_factory_at(hex_pos):
		return false
	
	# Player doesn't control this territory
	if not territories.has(hex_pos) or territories[hex_pos] != player_id:
		return false
	
	return true

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
	
