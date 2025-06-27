class_name GroundTileMap
extends TileMapLayer

var route: PackedScene = preload("res://scenes/transport/route.tscn")

@onready var map_parent = $".."

var start_point = null
var choosing_factory_tile = false
var factory_type = ''
var routes_end_points = []
	
func _ready():
	HexUtil.set_current_map(self)
	MapManager.set_map(self)
	HudManager.hud.on_building_factory.connect(_on_hud_on_building_factory)

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
			#if not TerritoryManager.territories.has(pos_clicked) or not TerritoryManager.territories[pos_clicked] == NetworkManager.player_id:
				#return
				
			if choosing_factory_tile:
				choosing_factory_tile = false
				HudManager.hud.update_label_status('Factory Built on ' + str(pos_clicked.x) + ', ' + str(pos_clicked.y))
				HudManager.hud.is_building_factory = false
				print(TerritoryManager.can_place_factory(pos_clicked))
				if TerritoryManager.can_place_factory(pos_clicked):
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
				ArmyManager.move_unit(pos_clicked, map_to_local(pos_clicked))


func add_route(path: Array) -> void:
	var path2d = route.instantiate()
	
	# connect with rpc
	
	get_tree().current_scene.find_child("Routes", true, false).add_child(path2d)
	path2d.create_route(path)
	

func _on_hud_on_building_factory(type: String) -> void:
	choosing_factory_tile = true
	factory_type = type
