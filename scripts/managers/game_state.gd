# GameState.gd - Main coordinator and central hub
# This should be added as an AUTOLOAD singleton in Project Settings
extends Node

# Core game signals
signal game_state_updated()
signal game_time_updated(new_time: float)
signal game_started()
#signal game_paused()
#signal game_resumed()

# Game state variables
var game_id: String = ""
var game_time: float = 0.0
var game_speed: float = 1.0
var is_paused: bool = false
var game_started_flag: bool = false
var map: MapConfiguration = preload("res://scenes/maps/dev_map.tres")

# Player data
var players: Dictionary = {}

func _ready():
	set_process(true)

func _process(delta):
	if not game_started_flag or is_paused:
		return
	
	# Update game time
	game_time += delta * game_speed
	game_time_updated.emit(game_time)

# Game control functions
func start_game():
	game_started_flag = true
	is_paused = false
	game_started.emit()

func pause_game():
	if not NetworkManager.is_host:
		return
	
	is_paused = true
	NetworkManager.sync_game_control("pause")
	#game_paused.emit()
#
#func resume_game():
	#if not NetworkManager.is_host:
		#return
	#
	#is_paused = false
	#NetworkManager.sync_game_control("resume")
	#game_resumed.emit()
#
#func set_game_speed(speed: float):
	#if not NetworkManager.is_host:
		#return
	#
	#game_speed = clamp(speed, 0.25, 5.0)
	#NetworkManager.sync_game_speed(game_speed)

# Player management
func add_player(id: int, player_name: String):
	players[id] = {
		"name": player_name,
		"color": Color.from_hsv(randf(), 0.8, 0.9),
		"factories_count": 0,
		"resources": {
			"materials": 100,
			"equipment": 0,
			"fuel": 50
		}
	}
	
	# Tell territory manager to assign starting territory
	#TerritoryManager.assign_starting_territory(id)
	game_state_updated.emit()
	print("Player added: ", player_name, " (ID: ", id, ")")

func get_player_data(player_id: int) -> Dictionary:
	return players.get(player_id, {})

func update_player_resources(player_id: int, resources: Dictionary):
	if players.has(player_id):
		players[player_id]["resources"] = resources
		game_state_updated.emit()

# Central state update notification
func notify_state_updated():
	game_state_updated.emit()

# Get all game data for saving/loading
func get_game_data() -> Dictionary:
	return {
		"game_id": game_id,
		"game_time": game_time,
		"game_speed": game_speed,
		"is_paused": is_paused,
		"game_started": game_started_flag,
		"players": players
	}

# Load game data
func load_game_data(data: Dictionary):
	game_id = data.get("game_id", "")
	game_time = data.get("game_time", 0.0)
	game_speed = data.get("game_speed", 1.0)
	is_paused = data.get("is_paused", false)
	game_started_flag = data.get("game_started", false)
	players = data.get("players", {})
	game_state_updated.emit()
