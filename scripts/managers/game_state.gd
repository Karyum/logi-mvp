# GameState.gd - Main coordinator and central hub
# This should be added as an AUTOLOAD singleton in Project Settings
extends Node

# Core game signals
signal game_state_updated()
#signal game_time_updated(new_time: float)
signal game_started()
#signal game_paused()
#signal game_resumed()
#signal game_battle_turn_started()

var game_timer: Timer = null

# Game state variables
var game_id: String = ""
var game_time: int = 1
var game_speed: float = 1.0
var is_paused: bool = false
var game_started_flag: bool = false
var game_battle_turn: int = 0
#var map: Resource = preload("res://scenes/maps/dev_map.tres")
var map: MapConfiguration = load("res://scenes/maps/dev_map_small.tres")

# Player data
var players: Dictionary = {}

var last_emit_ms = 0

func _ready():
	set_process(true)
	EventBus.game_battle_turn.connect(_on_game_battle_turn)



func _process(_delta):
	if not game_started_flag or is_paused:
		return
		
func create_timer():
	game_timer = Timer.new()
	game_timer.wait_time = 1.0
	game_timer.timeout.connect(_on_timer_timeout)
	add_child(game_timer)
	game_timer.start()

func _on_timer_timeout():
	game_time += 1
	
	# Host gets it immediately
	EventBus.time_updated.emit(game_time)
	EventBus.time_updated_rpc(game_time)
	
	if game_time / 10 > game_battle_turn:
		game_battle_turn += 1
		print(NetworkManager.player_id)
		EventBus.game_battle_turn.emit(game_battle_turn)
		EventBus.send_game_battle_turn_rpc(game_battle_turn)
		
	game_timer.start()
		

# Game control functions
func start_game():
	game_started_flag = true
	is_paused = false
	game_started.emit()
	if NetworkManager.is_host:
		create_timer()

func pause_game():
	if not NetworkManager.is_host:
		return
	
	is_paused = true
	NetworkManager.sync_game_control("pause")
	#game_paused.emit()

func resume_game():
	if not NetworkManager.is_host:
		return
	
	is_paused = false
	NetworkManager.sync_game_control("resume")
	#game_resumed.emit()

func set_game_speed(speed: float):
	if not NetworkManager.is_host:
		return
	
	game_speed = clamp(speed, 0.25, 5.0)
	NetworkManager.sync_game_speed(game_speed)

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


func _on_game_battle_turn(new_game_battle_turn: int):
	game_battle_turn = new_game_battle_turn
