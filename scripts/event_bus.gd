extends Node

signal time_updated(new_time: int)
signal game_battle_turn(new_game_battle_turn: int)
signal factory_placed(placing_player_id: int, hex_pos: Vector2i, factory_type: String)
signal factories_updated()

signal ui_factory_inventory_opened(pos: Vector2i)
signal ui_factory_inventory_closed()
signal item_is_held()
signal item_is_released()

	
func send_game_battle_turn_rpc(new_game_battle_turn: int):
	if multiplayer.is_server():
		send_game_battle_turn.rpc(new_game_battle_turn)

func time_updated_rpc(new_time: int):
	if multiplayer.is_server():
		send_game_timer.rpc(new_time)
		
func factory_placed_rpc(placing_player_id: int, hex_pos: Vector2i, factory_type: String):
	factory_placed_rpc_call.rpc(placing_player_id, hex_pos, factory_type)
		
func factory_sync_items_rpc(hex_pos: Vector2i, items: Array):
	var serialized = var_to_str(items)
	factory_sync_items_rpc_call.rpc(hex_pos, serialized)
	
func factories_sync_rpc(new_factories: Dictionary):
	var serialized = var_to_str(new_factories)
	factories_sync_rpc_call.rpc(serialized)
	
func factory_sync_items_request(hex_pos: Vector2i, items: Array):
	var serialized = var_to_str(items)
	factory_sync_items_request_rpc_call.rpc(hex_pos, serialized)
	
	
# RPCS

@rpc("authority", "call_remote", "reliable")
func send_game_battle_turn(new_game_battle_turn: int):
	game_battle_turn.emit(new_game_battle_turn)

@rpc("authority", "call_remote", "reliable")
func send_game_timer(new_game_time: int):
	time_updated.emit(new_game_time)

# NOTE RPC Client requests for game state change - START
@rpc("any_peer", "call_remote", "reliable")
func factory_place_request_rpc_call(placing_player_id: int, hex_pos: Vector2i, factory_type: String):
	if TerritoryManager.can_place_factory(hex_pos, placing_player_id):
		factory_placed_rpc_call.rpc(placing_player_id, hex_pos, factory_type)
		ProductionManager._create_factory(placing_player_id, hex_pos, factory_type)

@rpc("any_peer", "call_remote", "reliable")
func factory_sync_items_request_rpc_call(hex_pos: Vector2i, items: String):
	# ideally validate items, future problem
	factory_sync_items_rpc_call.rpc(hex_pos, items)
	ProductionManager.sync_factory_items(hex_pos, str_to_var(items) as Array[FactoryItemStorage])
	
	
@rpc("any_peer", "call_remote", "reliable")
func move_unit_request_rpc(unit_id: String, move_to: Vector2i):
	# ideally validate movement
	var army_data = ArmyManager.armies[unit_id]
	var fuel_cost = ArmyManager.get_fuel_cost(unit_id, move_to)
	
	if fuel_cost > army_data.total_fuel_amount:
		# TODO: dont't allow movement, maybe show message?
		pass
	else:
		move_unit_rpc.rpc(unit_id, move_to, fuel_cost)

@rpc("any_peer", "call_remote", "reliable")
func initiate_battle_request_rpc(battle_data: String):
	# ideally validate movement
	initiate_battle_rpc.rpc(battle_data)
	
# NOTE RPC Client requests for game state change - END

# NOTE TRANSPOORT RPCS - START
@rpc("authority", "call_remote", "reliable")
func transport_sync_trucks(new_trucks: String):
	TransportManager.sync_trucks(str_to_var(new_trucks))
# NOTE TRANSPOORT RPCS - END


# NOTE PRODUCTION RPCS - START
@rpc("authority", "call_local", "reliable")
func factory_placed_rpc_call(placing_player_id: int, hex_pos: Vector2i, factory_type: String):
	factory_placed.emit(placing_player_id, hex_pos, factory_type)
	
@rpc("authority", "call_remote", "reliable")
func factory_sync_items_rpc_call(hex_pos: Vector2i, items: String):
	ProductionManager.sync_factory_items(hex_pos, str_to_var(items) as Array[FactoryItemStorage])

@rpc("authority", "call_local", "reliable")
func factories_sync_rpc_call(new_factories: String):
	ProductionManager.sync_factories(str_to_var(new_factories) as Dictionary[Vector2i, Factory])

# NOTE PRODUCTION RPCS - END



# NOTE ARMY RPCS - START
@rpc("authority", "call_remote", "reliable")
func sync_starting_territory_rpc(armies_location: String) -> void:
	ArmyManager.armies = str_to_var(armies_location) as Dictionary[String, Army]
	
	ArmyManager.armies_spawned.emit(NetworkManager.player_id)
	NetworkManager.loading_screen_part_loaded_rpc.rpc("armies_spawned", NetworkManager.player_id)
	
@rpc("authority", "call_local", "reliable")
func move_unit_rpc(unit_id: String, move_to: Vector2i, fuel_cost: int):
	ArmyManager.move_unit(unit_id, move_to, fuel_cost)

@rpc("authority", "call_remote", "reliable")
func initiate_battle_rpc(battle_data: String):
	ArmyManager.initiate_battle(str_to_var(battle_data) as Battle)

# NOTE ARMY RPCS - END
