extends Node2D
class_name ArmyNode

@onready var move_tween: Tween
@onready var tank_sprite: Sprite2D = $SubViewportContainer/SubViewport/Node2D/Tank
@onready var infantry_sprite: Node2D = $SubViewportContainer/SubViewport/Node2D/Infantry
var line: Line2D

var is_moving: bool = false
var path_points = []
var current_point_index = 0

var is_my_army = false

var army_data: Dictionary = {
	'player_id': null,
	'current_pos': Vector2i.ZERO,
	'unit_id': '',
	'units': [],
}

func setup_army(unit_id: String, new_army_data: Army):
	is_my_army = NetworkManager.player_id == new_army_data.player_id
	
	tank_sprite.visible = false
	infantry_sprite.visible = false
		
	army_data['player_id'] = new_army_data.player_id
	army_data['current_pos'] = new_army_data.current_pos
	army_data['unit_id'] = unit_id
	army_data['units'] = new_army_data.units
	
	for unit in new_army_data.units:
		match unit.unit_type:
			ArmyUnit.UnitType.TANK:
				tank_sprite.visible = true
			ArmyUnit.UnitType.INFANTRY:
				infantry_sprite.visible = true

func move(move_to: Vector2i):
	var current_pos = army_data.current_pos
	
	if is_moving:
		var last_point = path_points[path_points.size() - 1]
		current_pos = HexUtil.global_to_cell(last_point)
		
	var path = HexUtil.get_waypoints_path([current_pos, move_to])
	
	if is_moving:
		path_points.append_array(path)

		if is_my_army:
			for point in path:
				line.add_point(point, line.get_point_count())
		return

	if is_my_army:
		create_pathline(path)

	path_points = path
	is_moving = true
	move_along_path()
	
func move_along_path():
	if current_point_index >= path_points.size():
		reach_position(HexUtil.global_to_cell(path_points[current_point_index - 1]))
		
		if is_my_army:
			line.clear_points()
		return
	
	
	var target = path_points[current_point_index]
	var target_cell = HexUtil.global_to_cell(target)
	
	if ArmyManager.is_enemy_army(target_cell) and is_my_army:
		reach_position(HexUtil.global_to_cell(path_points[current_point_index - 1]), true, target_cell)
		line.clear_points()
		return
	elif ArmyManager.is_my_army(target_cell) and not is_my_army:
		reach_position(HexUtil.global_to_cell(path_points[current_point_index - 1]))
		return

	# Create a new tween
	move_tween = create_tween()
	
	# Move to the next point
	var duration = position.distance_to(target) / 75.0  # Adjust speed as needed
	
	move_tween.tween_property(self, "position", target, duration)
	move_tween.tween_callback(move_to_next_point)
	
func move_to_next_point():
	
	if is_my_army and line.get_point_count() > 0 and current_point_index - 1 >= 0 :
		line.remove_point(0)

	current_point_index += 1
	move_along_path()
	

func reach_position(pos_reached: Vector2i, did_start_battle: bool = false, enemy_pos: Vector2i = Vector2i.ZERO):
	is_moving = false
	army_data['current_pos'] = pos_reached
	ArmyManager.unit_reach_pos(army_data['unit_id'], pos_reached, did_start_battle, enemy_pos)
	current_point_index = 0
	path_points = []

	if is_my_army:
		line.queue_free()

func create_pathline(path):
	line = Line2D.new()
	var parent = get_tree().current_scene.get_node("Misc")
	parent.add_child(line)
	line.z_index = 0
	line.width = 3
	line.default_color = '#00ffff8d'
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	for point in path:
		line.add_point(point)
