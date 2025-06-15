class_name GroundTileMap
extends TileMapLayer

var route: PackedScene = preload("res://scenes/transport/route.tscn")


@onready var HUD: CanvasLayer = $"../../HUD"

var start_point = null
var choosing_building_tile = false
var buildingType = ''
var routes_end_points = []
	
func _ready():
	HexNavi.set_current_map(self)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var global_clicked = get_global_mouse_position()
			var pos_clicked = local_to_map(to_local(global_clicked))
			var tile_data = self.get_cell_tile_data(pos_clicked)
				
			#if (tile_data.get_custom_data("prevent_click")):
				#return
			
			if choosing_building_tile:
				choosing_building_tile = false
				HUD.update_label_status('Factory Built on ' + str(pos_clicked.x) + ', ' + str(pos_clicked.y))
				if TerritoryManager.can_place_factory(pos_clicked):
					TerritoryManager.place_factory_local(pos_clicked, buildingType)
				pass
			else:
				if not start_point:
					start_point = pos_clicked
				else:
					routes_end_points.append([start_point, pos_clicked])
					var path = HexNavi.get_waypoints_path([start_point, pos_clicked])
					add_route(path)
					start_point = null


func add_route(path: Array) -> void:
	var path2d = route.instantiate()
	
	get_tree().current_scene.find_child("Routes", true, false).add_child(path2d)
	path2d.create_route(path)
	

func _on_hud_on_building_factory(type: String) -> void:
	choosing_building_tile = true
	buildingType = type
	
func build_terratory(player_terratory: Array[Vector2i]):
	print('build_terratory', player_terratory)
	pass
