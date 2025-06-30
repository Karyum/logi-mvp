extends Node

signal time_updated(new_time: int)
signal game_battle_turn(new_game_battle_turn: int)
signal factory_placed(placing_player_id: int, hex_pos: Vector2i, factory_type: String)
signal ui_factory_inventory_opened(pos: Vector2i)
signal ui_factory_inventory_closed()

#func _ready() -> void:
	#game_battle_turn.connect(_on_send_game_battle_turn)
	#time_updated.connect(_on_time_updated)
	
	
func send_game_battle_turn_rpc(new_game_battle_turn: int):
	if multiplayer.is_server():
		send_game_battle_turn.rpc(new_game_battle_turn)

func time_updated_rpc(new_time: int):
	if multiplayer.is_server():
		send_game_timer.rpc(new_time)
		
func factory_placed_rpc(placing_player_id: int, hex_pos: Vector2i, factory_type: String):
	place_factory_rpc.rpc(placing_player_id, hex_pos, factory_type)
		

@rpc("authority", "call_remote", "reliable")
func send_game_battle_turn(new_game_battle_turn: int):
	game_battle_turn.emit(new_game_battle_turn)

@rpc("authority", "call_remote", "reliable")
func send_game_timer(new_game_time: int):
	time_updated.emit(new_game_time)

@rpc("any_peer", "call_remote", "reliable")
func place_factory_rpc(placing_player_id: int, hex_pos: Vector2i, factory_type: String):
	factory_placed.emit(placing_player_id, hex_pos, factory_type)
