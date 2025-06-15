extends Node

var factories: Dictionary = {}  # hex_pos -> Factory data


func add_factory(hex_pos: Vector2, factory_data: Dictionary):
	factories[hex_pos] = factory_data
	
	# Update player factory count
	var owner_id = factory_data.get("owner_id", 0)
	if GameState.players.has(owner_id):
		GameState.players[owner_id].factories_count += 1
	
	#sync_production_rpc.rpc(factories)
	#
#@rpc("any_peer", "call_local", "reliable")
#func sync_production_rpc(updated_factories: Dictionary):
	#factories = updated_factories
	#GameState.notify_state_updated()
