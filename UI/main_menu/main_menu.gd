extends Control

@onready var ip_input: TextEdit = $ColorRect/HBoxContainer/VBoxContainer/TextEdit
@onready var name_input: TextEdit = $ColorRect/HBoxContainer/Name
@onready var join_button: Button = $ColorRect/HBoxContainer/VBoxContainer/Join
@onready var host_button: Button = $ColorRect/HBoxContainer/VBoxContainer/Host
var lobby: PackedScene = preload("res://UI/lobby/lobby.tscn")

func _ready() -> void:
	NetworkManager.connected_to_server.connect(_on_connection_successful)
	ip_input.text = NetworkManager.get_local_ip()

func _on_join_pressed() -> void:
	NetworkManager.join_game(ip_input.text, 7000, name_input.text)
	

func _on_connection_successful():
	get_tree().change_scene_to_packed(lobby)

func _on_text_edit_text_changed() -> void:
	join_button.disabled = !ip_input.text
	join_button.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND if ip_input.text else CursorShape.CURSOR_FORBIDDEN

func _on_name_text_changed() -> void:
	if !name_input.text:
		return
	
	host_button.disabled = !name_input.text
	host_button.mouse_default_cursor_shape = CursorShape.CURSOR_POINTING_HAND if name_input.text else CursorShape.CURSOR_FORBIDDEN

	
func _on_host_pressed() -> void:
	NetworkManager.host_game(7000, name_input.text)
	get_tree().change_scene_to_packed(lobby)
