extends Control

var loaded_territories = 0
var spawned_armies = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# DEV ONLY 
	for arg in OS.get_cmdline_args():
		if arg == 'server':
			NetworkManager.host_game()
		elif arg == 'client':
			NetworkManager.join_game(NetworkManager.get_local_ip())
	
	# DEV ONLY
	NetworkManager.player_joined_lobby.connect(_on_player_joined_lobby)
	
	TerritoryManager.territory_data_loaded.connect(_on_player_territory_loaded)
	ArmyManager.armies_spawned.connect(_on_armies_spawned)
	GameState.game_started.connect(_on_game_started)
	NetworkManager.loading_screen_part_loaded.connect(_on_player_loading_part_loaded)
	
	# on ready call the TerritoryManager.assign_starting_territory function as a start
	# after that get the starting position then move and rotate the camera to it
	# as if looking at the other player
	if NetworkManager.is_host:
		# DEV ONLY
		await get_tree().create_timer(1).timeout
		
		await TerritoryManager.assign_starting_territory()
		ArmyManager.assign_armies_spawners()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_player_loading_part_loaded(check_name: String, _player_id: int):
	match check_name:
		'territory_data':
			loaded_territories += 1
		'armies_spawned':
			spawned_armies += 1

	update_progress()
	
func _on_player_territory_loaded(_player_id: int):
	loaded_territories += 1
	update_progress()

func _on_armies_spawned(_player_id: int):
	spawned_armies += 1
	update_progress()
	
	
func _on_player_joined_lobby(player_id: int, player_name: String):
	GameState.add_player(player_id, player_name)
	NetworkManager.send_state_to_client(player_id)
	
func update_progress():
	var value: int = 0
	var total_checks: int = 2
	var players_amount = GameState.players.keys().size()
	
	if loaded_territories == players_amount:
		value += int(100 / total_checks)
		
	if spawned_armies == players_amount:
		value += int(100 / total_checks)
	
	#print({
		#'player_id': NetworkManager.player_id,
		#'value': value,
		#'spawned_armies': spawned_armies,
		#'loaded_territories': loaded_territories,
		#'players_amount': players_amount
	#})
		
	$ColorRect/ProgressBar.value = value
	if value == 100:
		NetworkManager.start_game_from_lobby()
		
		
func _on_game_started():
	get_tree().call_deferred("change_scene_to_file", "res://scenes/level/level.tscn")
