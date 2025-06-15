extends Control

@onready var player_list: VBoxContainer = $ColorRect/VBoxContainer/PlayerList
@onready var start_button: Button = $ColorRect/VBoxContainer/Start
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if NetworkManager.is_host:
		build_lobby_list(NetworkManager.lobby_players)
		start_button.visible = true

	NetworkManager.player_joined_lobby.connect(_on_player_joined_lobby)
	
	if not NetworkManager.is_host:
		NetworkManager.lobby_updated.connect(build_lobby_list)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	NetworkManager.go_to_loading_rpc.rpc()
	

func _on_back_to_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/main_menu/main_menu.tscn")

func _on_player_joined_lobby(_player_id: int, player_name: String):
	var label = Label.new()
	label.text = player_name
	player_list.add_child(label)
	
	
# Future todo: when a peer connects their lobby_updated signal runs twice
# would be nice to prevent that
func build_lobby_list(players: Dictionary):
	print(NetworkManager.player_id, ' build_lobby_list')
	if player_list.get_child_count() == players.size():
		return
	
	for child in player_list.get_children():
		child.queue_free()

	for key in players:
		var label = Label.new()
		var player_data = NetworkManager.lobby_players[key]
		label.text = player_data.name
		player_list.add_child(label)
