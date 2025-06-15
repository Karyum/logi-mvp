extends Control

var loaded_terratories = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# DEV ONLY 
	for arg in OS.get_cmdline_args():
		if arg == 'server':
			NetworkManager.host_game()
		elif arg == 'client':
			var player_data = NetworkManager.join_game(NetworkManager.get_local_ip())
			await get_tree().create_timer(0.25).timeout
			GameState.add_player(player_data['player_id'], 'client')
			GameState.add_player(1, 'Host')
	
	# DEV ONLY
	NetworkManager.player_joined_lobby.connect(_on_player_joined_lobby)
	
	TerritoryManager.terratory_data_loaded.connect(_on_player_terratory_loaded)
	GameState.game_started.connect(_on_game_started)
	
	# on ready call the TerritoryManager.assign_starting_territory function as a start
	# after that get the starting position then move and rotate the camera to it
	# as if looking at the other player
	if NetworkManager.is_host:
		# DEV ONLY 
		await get_tree().create_timer(0.5).timeout
		
		TerritoryManager.assign_starting_territory()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _on_player_terratory_loaded(_player_id: int):
	loaded_terratories += 1
	update_progress()
	
func _on_player_joined_lobby(player_id: int, player_name: String):
	GameState.add_player(player_id, player_name)
	
func update_progress():
	var value: int = 0
	var total_checks: int = 1
	var players_amount = GameState.players.keys().size()
	
	if loaded_terratories == 2:
		value = int(100 / total_checks)
	
		
	$ColorRect/ProgressBar.value = value
	if value == 100:
		NetworkManager.start_game_from_lobby()
		
		
func _on_game_started():
	get_tree().call_deferred("change_scene_to_file", "res://scenes/level/level.tscn")
