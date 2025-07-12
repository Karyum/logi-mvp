extends Node

var army_unit: PackedScene = preload("res://scenes/combat/army.tscn")
var battle_particles: PackedScene = preload("res://scenes/particles/battle_particles.tscn")
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
			var player_id = TerritoryManager.territories[army_spawn_point.position as Vector2i]
			var unit_id = 'army ' + str(index) + '-' + str(player_id)
	
			var army_data = Army.new()
			army_data.player_id = player_id
			army_data.current_pos = army_spawn_point.position
			army_data.units = army_spawn_point.units
			army_data.unit_id = unit_id
			
			for unit in army_spawn_point.units:
				army_data.total_fuel_amount += unit.fuel_amount
				army_data.total_fuel_cons_rate += unit.fuel_cons_rate
				
				army_data.total_fuel_amount += unit.food_amount
				army_data.total_food_cons_rate += unit.food_cons_rate
			
			armies[unit_id] = army_data

			index += 1

	EventBus.sync_starting_territory_rpc.rpc(var_to_str(armies))
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
	selected_army.select_unit()

	
func unselect_unit():
	if is_instance_valid(selected_army):
		selected_army.unselect_unit()
		selected_army = null
	
func is_unit_selected():
	return selected_army
	
func move_unit_request(move_to: Vector2i, _global_pos: Vector2):
	if NetworkManager.is_host:
		var fuel_cost = get_fuel_cost(selected_army.army_data.unit_id, move_to)
		
		if fuel_cost > selected_army.army_data.total_fuel_amount:
			return
		
		EventBus.move_unit_rpc.rpc(selected_army.army_data.unit_id, move_to, fuel_cost)
	else:
		EventBus.move_unit_request_rpc.rpc(selected_army.army_data.unit_id, move_to)

func move_unit(unit_id: String, move_to: Vector2i, fuel_cost: int):
	ArmyManager.armies[unit_id].total_fuel_amount -= fuel_cost
	ArmyManager.armies_nodes[unit_id].move(move_to, fuel_cost)

func get_fuel_cost(unit_id: String, move_to: Vector2i):
	var army_data = armies[unit_id]
	var path = HexUtil.get_waypoints_path([army_data.current_pos, move_to])
	var path_fuel_cost = HexUtil.get_fuel_cost(army_data.current_pos, move_to)
	var fuel_cost = ((path.size() - 1) * army_data.total_food_cons_rate) + path_fuel_cost
	
	return fuel_cost

func unit_reach_pos(unit_id: String, pos: Vector2i, did_start_battle: bool = false, enemy_pos: Vector2i = Vector2i.ZERO):
	armies[unit_id].current_pos = pos
	
	if armies[unit_id].player_id == NetworkManager.player_id:
		TerritoryManager.capture_hex(pos)
	
	if did_start_battle:
		var enemy_unit_id = is_enemy_army(enemy_pos)
		
		var battle_data = Battle.new()
		battle_data.attacker = armies[unit_id]
		battle_data.defender = armies[enemy_unit_id]
		
		
		if NetworkManager.is_host:
			initiate_battle(battle_data)
			EventBus.initiate_battle_rpc.rpc(var_to_str(battle_data))
		else:
			EventBus.initiate_battle_request_rpc.rpc(var_to_str(battle_data))

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
