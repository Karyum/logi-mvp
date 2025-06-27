extends Node

var army_unit: PackedScene = preload("res://scenes/combat/army.tscn")
var battle_particles: PackedScene = preload("res://scenes/particles/battle_particles.tscn")
var outline_shader: Shader = preload("res://shaders/unit_ountline.gdshader")
var pre_combat_progress_bar: PackedScene = preload("res://scenes/combat/pre_combat_progress.tscn")

@onready var tree = get_tree()

signal armies_spawned()

var armies: Dictionary[String, Army] = {} 
var armies_nodes: Dictionary[String, ArmyNode] = {}
var selected_army: ArmyNode = null
var battles: Array[Battle] = []

func _ready() -> void:
	EventBus.game_battle_turn.connect(_on_game_battle_turn)
	EventBus.time_updated.connect(_on_game_time_updated)


func assign_armies_spawners():
	
	for player_army in GameState.map.armies:
		var index = 1
		
		for army_spawn_point: ArmySpawnPointResource in player_army.spawners:
			var player_id = TerritoryManager.territories[army_spawn_point.position]
			var unit_id = 'army ' + str(index) + '-' + str(player_id)
	
			var army_data = Army.new()
			army_data.player_id = player_id
			army_data.current_pos = army_spawn_point.position
			army_data.units = army_spawn_point.units
			army_data.unit_id = unit_id
			
			armies[unit_id] = army_data

			index += 1

	sync_starting_territory_rpc.rpc(var_to_str(armies))
	armies_spawned.emit(NetworkManager.player_id)
	

func army_belong_to_player(pos: Vector2i, player_id: int) -> Variant:
	for unit_id in armies:
		if armies[unit_id].current_pos == pos and armies[unit_id].player_id == player_id:
			return unit_id
	return false

func is_my_army(pos: Vector2i) -> Variant:
	for unit_id in armies:
		if armies[unit_id].current_pos == pos and armies[unit_id].player_id == NetworkManager.player_id:
			return unit_id
	return false

func is_enemy_army(pos: Vector2i) -> Variant:
	for unit_id in armies:
		if armies[unit_id].current_pos == pos and armies[unit_id].player_id != NetworkManager.player_id:
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
	if selected_army:
		selected_army.find_child('SubViewportContainer').material = null
	
	selected_army = armies_nodes[unit_id]
	
	var sprite: SubViewportContainer = selected_army.get_child(0)
	var shader_material = ShaderMaterial.new()
	shader_material.shader = outline_shader
	sprite.material = shader_material
	
func unselect_unit():
	selected_army = null
	
func is_unit_selected():
	return selected_army
	
func move_unit(unit_pos: Vector2i, _global_pos: Vector2):
	selected_army.move(unit_pos)
	move_unit_rpc.rpc(selected_army.army_data.unit_id, unit_pos)

	
func unit_reach_pos(unit_id: String, pos: Vector2i, did_start_battle: bool = false, enemy_pos: Vector2i = Vector2i.ZERO):
	armies[unit_id]['current_pos'] = pos
	
	if armies[unit_id].player_id == NetworkManager.player_id:
		TerritoryManager.capture_hex(pos)
	
	if did_start_battle:
		var enemy_unit_id = is_enemy_army(enemy_pos)
		
		var battle_data = Battle.new()
		battle_data.attacker = armies[unit_id]
		battle_data.defender = armies[enemy_unit_id]
		
		
		initiate_battle(battle_data)
		sync_initiate_battle(battle_data)
		

func initiate_battle(battle_data: Battle):
	var center_point = (HexUtil.cell_to_global(battle_data.attacker.current_pos) + HexUtil.cell_to_global(battle_data.defender.current_pos)) / 2
	var parent = get_tree().current_scene.get_node("Misc")
	var particles: GPUParticles2D = battle_particles.instantiate()
	parent.add_child(particles)
	particles.global_position = center_point
	
	var progress_bar: ProgressBar = pre_combat_progress_bar.instantiate()
	parent.add_child(progress_bar)
	progress_bar.global_position = center_point + Vector2(-(HexUtil.cell_size_x / 4), (HexUtil.cell_size_y / 4))
	
	battle_data.progress_bar = progress_bar
	
	# 20 is the max and we deduct in every second
	battle_data.progress = 20
	battles.append(battle_data)
	
	
func _on_game_battle_turn(_new_battle_turn: int):
	pass
	# see existing battles and start resolving them

func _on_game_time_updated(_new_time: int):
	for battle in battles:
		battle.progress -= 1
		battle.progress_bar.value -= 1
		
		if battle.progress == 0:
			# resolve battle
			pass

func sync_initiate_battle(battle_data: Battle):
	var serialized = var_to_str(battle_data)
	initiate_battle_rpc.rpc(serialized)

# NETWORK
@rpc("authority", "call_remote", "reliable")
func sync_starting_territory_rpc(armies_location: String) -> void:
	armies = str_to_var(armies_location) as Dictionary[String, Army]
	
	armies_spawned.emit(NetworkManager.player_id)
	NetworkManager.loading_screen_part_loaded_rpc.rpc("armies_spawned", NetworkManager.player_id)


@rpc("any_peer", "call_remote", "reliable")
func move_unit_rpc(unit_id: String, move_to: Vector2i):
	armies_nodes[unit_id].move(move_to)

@rpc("any_peer", "call_remote", "reliable")
func initiate_battle_rpc(battle_data: String):
	initiate_battle(str_to_var(battle_data) as Battle)
