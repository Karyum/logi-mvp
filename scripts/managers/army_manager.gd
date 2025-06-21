extends Node

var army_unit: PackedScene = preload("res://scenes/army.tscn")
var battle_particles: PackedScene = preload("res://scenes/particles/battle_particles.tscn")
var outline_shader: Shader = preload("res://shaders/unit_ountline.gdshader")

@onready var tree = get_tree()

signal armies_spawned()

var armies: Dictionary = {} 
var armies_nodes: Dictionary = {}
var selected_unit: ArmyUnit = null
var battles: Array = []

func assign_armies_spawners():
	
	for player_army in GameState.map.armies:
		var index = 1
		
		for army_pos in player_army.spawners:
			var player_id = TerritoryManager.territories[army_pos]
			var unit_id = 'army ' + str(index) + '-' + str(player_id)
			armies[unit_id] = {
				'player_id': player_id,
				'current_pos': army_pos
			}
			index += 1

	sync_starting_territory_rpc.rpc(armies)
	armies_spawned.emit(NetworkManager.player_id)
	

func army_belong_to_player(pos: Vector2i, player_id: int):
	for unit_id in armies:
		if armies[unit_id]["current_pos"] == pos and armies[unit_id]["player_id"] == player_id:
			return unit_id
	return false

func is_enemy_unit(pos: Vector2i):
	for unit_id in armies:
		if armies[unit_id]["current_pos"] == pos and armies[unit_id]["player_id"] != NetworkManager.player_id:
			return unit_id
	return false

func spawn_armies():
	var armies_parent = tree.current_scene.get_node("Armies")
	
	for army_unit_id in armies.keys():
		var army_node = army_unit.instantiate() as Node2D
		var army_data = armies[army_unit_id]
		army_node.position = MapManager.map.map_to_local(army_data.current_pos)
		armies_parent.add_child(army_node)
		army_node.setup_army(army_unit_id, army_data)
		armies_nodes[army_unit_id] = army_node

func select_unit(unit_id: String):
	if selected_unit:
		selected_unit.find_child('Sprite2D').material = null
	
	selected_unit = armies_nodes[unit_id]
	
	var sprite: Sprite2D = selected_unit.get_child(0)
	var shader_material = ShaderMaterial.new()
	shader_material.shader = outline_shader
	sprite.material = shader_material
	
func unselect_unit():
	selected_unit = null
	
func is_unit_selected():
	return selected_unit
	
func move_unit(unit_pos: Vector2i, _global_pos: Vector2):
	selected_unit.move(unit_pos)
	# Check if the next tile is an enemy army, the start battle instead

	
func unit_reach_pos(unit_id: String, pos: Vector2i, did_start_battle: bool = false, enemy_pos: Vector2i = Vector2i.ZERO):
	armies[unit_id]['current_pos'] = pos
	
	TerritoryManager.capture_hex(pos)
	
	if did_start_battle:
		var enemy_unit_id = is_enemy_unit(enemy_pos)
		
		var battle_data = {
			'army1': armies[unit_id],
			'army2': armies[enemy_unit_id]
		}
		
		initiate_battle(battle_data)
		

func initiate_battle(battle_data: Dictionary):
	battles.append(battle_data)
	
	var center_point = (HexUtil.cell_to_global(battle_data['army1']['current_pos']) + HexUtil.cell_to_global(battle_data['army2']['current_pos'])) / 2
	var parent = get_tree().current_scene.get_node("Misc")
	var particles: GPUParticles2D = battle_particles.instantiate()
	parent.add_child(particles)
	particles.global_position = center_point
	
	

# NETWORK
@rpc("authority", "call_remote", "reliable")
func sync_starting_territory_rpc(armies_location: Dictionary):
	armies = armies_location
	armies_spawned.emit(NetworkManager.player_id)
	NetworkManager.loading_screen_part_loaded_rpc.rpc('armies_spawned', NetworkManager.player_id)

@rpc("authority", "call_remote", "reliable")
func send_new_battle_data(battle_data: Dictionary):
	initiate_battle(battle_data)
