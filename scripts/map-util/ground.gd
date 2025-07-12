class_name GroundTileMap
extends TileMapLayer

var route: PackedScene = preload("res://scenes/transport/route.tscn")
var fuel_cons_scene: PackedScene = preload('res://UI/small/fuel_usage/fuel_usage.tscn')

@onready var map_parent = $".."

var start_point = null
var choosing_factory_tile = false
var factory_type = ''
var routes_end_points = []
var currently_hovered_pos: Vector2i

var pathline: Line2D
var fuel_cons_label: Control
	
func _ready():
	HexUtil.set_current_map(self)
	MapManager.set_map(self)
	HudManager.hud.on_building_factory.connect(_on_hud_on_building_factory)
	
func _process(_delta: float) -> void:
	var global_mouse_pos = get_global_mouse_position()
	var hex_pos = local_to_map(to_local(global_mouse_pos))
	
	if currently_hovered_pos != hex_pos:
		currently_hovered_pos = hex_pos
		
		_on_hex_hover_changed()
	
func _on_hex_hover_changed():
	if ArmyManager.is_unit_selected():
		if is_instance_valid(pathline):
			pathline.queue_free()
			fuel_cons_label.queue_free()
			
		var army_pos;
		
		if ArmyManager.selected_army.is_moving:
			army_pos = local_to_map(ArmyManager.selected_army.path_points[ArmyManager.selected_army.path_points.size() - 1])
		else:
			army_pos = ArmyManager.selected_army.army_data['current_pos']
		
		var path = HexUtil.get_waypoints_path([army_pos, currently_hovered_pos])
		
		if path.is_empty(): return
		
		pathline = Line2D.new()
		var parent = get_tree().current_scene.get_node("Misc")
		parent.add_child(pathline)
		pathline.z_index = 0
		pathline.width = 3
		pathline.default_color = '#ff00ff8d'
		pathline.joint_mode = Line2D.LINE_JOINT_ROUND
		pathline.begin_cap_mode = Line2D.LINE_CAP_ROUND
		pathline.end_cap_mode = Line2D.LINE_CAP_ROUND
		
		for point in path:
			pathline.add_point(point)
			
		fuel_cons_label = fuel_cons_scene.instantiate()
		fuel_cons_label.global_position = path[path.size() - 1] + Vector2(20, 0)
		var move_fuel_cost = ArmyManager.get_fuel_cost(ArmyManager.selected_army.army_data.unit_id, currently_hovered_pos)
		fuel_cons_label.update_text(move_fuel_cost)
		parent.add_child(fuel_cons_label)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		var global_clicked = get_global_mouse_position()
		var pos_clicked = local_to_map(to_local(global_clicked))
		var tile_data = self.get_cell_tile_data(pos_clicked)

		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			
			if not tile_data:
				return
			
			if tile_data.get_custom_data("prevent_click"):
				return
			
			var unit_id = ArmyManager.army_belong_to_player(pos_clicked, NetworkManager.player_id)
			if unit_id:
				if ArmyManager.selected_army and ArmyManager.selected_army.army_data['current_pos'] == pos_clicked :
					return
				else:
					ArmyManager.select_unit(unit_id)
					return
			else:
				ArmyManager.unselect_unit()
				if is_instance_valid(pathline): pathline.queue_free()
				if is_instance_valid(fuel_cons_label): fuel_cons_label.queue_free()
				
			#if not TerritoryManager.territories.has(pos_clicked) or not TerritoryManager.territories[pos_clicked] == NetworkManager.player_id:
				#return
				
			if choosing_factory_tile:
				choosing_factory_tile = false
				HudManager.hud.update_label_status('Factory Built on ' + str(pos_clicked.x) + ', ' + str(pos_clicked.y))
				HudManager.hud.is_building_factory = false

				if TerritoryManager.can_place_factory(pos_clicked, NetworkManager.player_id):
					ProductionManager.add_factory(NetworkManager.player_id ,pos_clicked, factory_type)
			else:
				pass
				#if not start_point:
					#start_point = pos_clicked
				#else:
					#routes_end_points.append([start_point, pos_clicked])
					#var path = HexUtil.get_waypoints_path([start_point, pos_clicked])
					#add_route(path)
					#start_point = null
					
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			if not tile_data:
				return
			
			if tile_data.get_custom_data("prevent_click"):
				return
		
			if ArmyManager.is_unit_selected():
				pathline.queue_free()
				fuel_cons_label.queue_free()
				ArmyManager.move_unit_request(pos_clicked, map_to_local(pos_clicked))


func add_route(path: Array) -> void:
	var path2d = route.instantiate()
	
	# connect with rpc
	
	get_tree().current_scene.find_child("Routes", true, false).add_child(path2d)
	path2d.create_route(path)
	

func _on_hud_on_building_factory(type: String) -> void:
	choosing_factory_tile = true
	factory_type = type
