# NetworkManager.gd - Handle all multiplayer networking
# This should be added as an AUTOLOAD singleton in Project Settings
extends Node

# Network-related signals
signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal connected_to_server()
signal connection_failed()
signal player_joined_lobby(player_id: int, player_name: String)
signal player_left_lobby(player_id: int)
signal lobby_updated(players: Dictionary)

signal loading_screen_part_loaded(check_name: String, player_id: int)

# Network state
var multiplayer_peer: MultiplayerPeer
var is_host: bool = false
var player_id: int = 0
# Lobby state
var lobby_players: Dictionary = {}

func _ready():
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	print("NetworkManager initialized")

func get_local_ip() -> String:
	# Try to get the most appropriate local IP
	var addresses = IP.get_local_addresses()
	
	# Prefer non-loopback, IPv4 addresses
	for addr in addresses:
		if addr.begins_with("172.") and not addr.begins_with("::") and addr.count(".") == 3:
			return addr
	# Fallback to first available address
	if addresses.size() > 0:
		return addresses[0]
	
	# Ultimate fallback
	return "127.0.0.1"

# Host a game
func host_game(port: int = 7002, player_name: String = 'Potato Host'):
	multiplayer_peer = ENetMultiplayerPeer.new()
	multiplayer_peer.create_server(port, 4)  # Max 4 players
	multiplayer.multiplayer_peer = multiplayer_peer
	is_host = true
	player_id = 1
	multiplayer_peer.get_connection_status()
	lobby_players[player_id] = {
		"name": player_name,
		"ready": false
	}
	
	# Add host as first player
	GameState.add_player(1, "Host")
	#print("Game hosted on port ", get_local_ip(), ":", port)

# Join a game
func join_game(ip: String = "127.0.0.1", port: int = 7002, player_name: String = "Player") -> Dictionary:
	multiplayer_peer = ENetMultiplayerPeer.new()
	multiplayer_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = multiplayer_peer
	is_host = false
	
	# Store player name for when we connect
	set_meta("pending_player_name", player_name)
	print("Attempting to join game at ", ip, ":", port)
	
	return {
		'player_name': player_name,
		'player_id': multiplayer_peer.get_unique_id()
	}

# Add player to lobby
func add_player_to_lobby(id: int, player_name: String):
	lobby_players[id] = {
		"name": player_name,
		"ready": false
	}
	player_joined_lobby.emit(id, player_name)
	lobby_updated.emit(lobby_players)
	print("Player added to lobby: ", player_name, " (ID: ", id, ")")

# Remove player from lobby
func remove_player_from_lobby(id: int):
	if lobby_players.has(id):
		var player_name = lobby_players[id]["name"]
		lobby_players.erase(id)
		player_left_lobby.emit(id)
		lobby_updated.emit(lobby_players)
		print("Player left lobby: ", player_name, " (ID: ", id, ")")

# Set player ready status
func set_player_ready(id: int, is_ready: bool):
	if lobby_players.has(id):
		lobby_players[id]["ready"] = is_ready
		sync_lobby_state()
		lobby_updated.emit(lobby_players)

# Check if all players are ready
func are_all_players_ready() -> bool:
	if lobby_players.size() < 2:  # Need at least 2 players
		return false
	
	for player_data in lobby_players.values():
		if not player_data["ready"]:
			return false
	return true

# Start the game (host only)
func start_game_from_lobby():
	if not is_host:
		print("Only host can start the game")
		return false
	
	#if not are_all_players_ready():
		#print("Not all players are ready")
		#return false
	
	# Add all lobby players to GameState
	for lobby_player_id in lobby_players.keys():
		var player_data = lobby_players[lobby_player_id]
		GameState.add_player(lobby_player_id, player_data["name"])
	
	sync_full_game_state()
	# Start the game
	sync_game_control("start")
	
	return true

# Sync lobby state to all clients
func sync_lobby_state():
	sync_lobby_rpc.rpc(lobby_players)

@rpc("authority", "call_local", "reliable")
func sync_lobby_rpc(players: Dictionary):
	lobby_players = players
	lobby_updated.emit(lobby_players)

# Sync game control commands
func sync_game_control(action: String):
	sync_game_control_rpc.rpc(action)

@rpc("authority", "call_local", "reliable")
func sync_game_control_rpc(action: String):
	match action:
		"start":
			GameState.start_game()
		"pause":
			GameState.pause_game()
		"resume":
			GameState.resume_game()

# Sync game speed
func sync_game_speed(speed: float):
	sync_game_speed_rpc.rpc(speed)

@rpc("authority", "call_local", "reliable")
func sync_game_speed_rpc(speed: float):
	GameState.game_speed = speed

# Sync entire game state to all clients
func sync_full_game_state():
	var game_data = GameState.get_game_data()
	#var territory_data = TerritoryManager.get_territory_data()
	#var production_data = ProductionManager.get_production_data()
	
	#sync_full_state_rpc.rpc(game_data, territory_data, production_data)
	sync_full_state_rpc.rpc(game_data)

@rpc("authority", "call_remote", "reliable")
#func sync_full_state_rpc(game_data: Dictionary, territory_data: Dictionary, _production_data: Dictionary):
func sync_full_state_rpc(game_data: Dictionary):
	GameState.load_game_data(game_data)
	#TerritoryManager.load_territory_data(territory_data)
	#ProductionManager.load_production_data(production_data)

# Send state to specific client (for new connections)
func send_state_to_client(client_id: int):
	var game_data = GameState.get_game_data()
	#var territory_data = TerritoryManager.get_territory_data()
	#var production_data = ProductionManager.get_production_data()
	
	#sync_full_state_rpc.rpc_id(client_id, game_data, territory_data, production_data)
	sync_full_state_rpc.rpc_id(client_id, game_data)

# Multiplayer event handlers
func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	peer_connected.emit(id)
	
	if is_host:
		# Send current game state to new player
		send_state_to_client(id)
		# Send current lobby state to new player
		sync_lobby_rpc.rpc_id(id, lobby_players)
		
		# If game is already running, send full game state
		if GameState.game_started_flag:
			send_state_to_client(id)
		

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	
	# Remove from lobby
	remove_player_from_lobby(id)

	if GameState.players.has(id):
		GameState.players.erase(id)
		GameState.notify_state_updated()
	peer_disconnected.emit(id)

func _on_connected_to_server():
	print("Connected to server")
	player_id = multiplayer.get_unique_id()
	
	# Request to join lobby with our name
	var player_name = get_meta("pending_player_name", "Player")
	join_lobby.rpc_id(1, player_id, player_name)  # Send to host
	
	connected_to_server.emit()

# RPC for client to request joining lobby
@rpc("any_peer", "call_local", "reliable")
func join_lobby(id: int, player_name: String):
	if is_host:
		add_player_to_lobby(id, player_name)
		sync_lobby_state()
		
func _on_connection_failed():
	print("Failed to connect to server")
	connection_failed.emit()

@rpc('authority', 'call_local', 'reliable')
func go_to_loading_rpc():
	get_tree().change_scene_to_file("res://UI/loading_screen/loading_screen.tscn")

@rpc('any_peer', 'call_remote', 'reliable')
func loading_screen_part_loaded_rpc(check_name: String, loaded_player_id: int):
	print({
		'p1': player_id,
		'p2': loaded_player_id,
		'check_name': check_name
	})
	loading_screen_part_loaded.emit(check_name, loaded_player_id)
