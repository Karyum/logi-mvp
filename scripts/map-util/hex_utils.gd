extends Node

#Method documentation: https://docs.google.com/document/d/1HwLlRmC2tDGbadkOEero5asVq6XmzpupeJX_pUEwqGg/edit?usp=sharing

var current_map : TileMapLayer
var astar = AStar2D.new()
var cell_size_x = 120
var cell_size_y = 138

## Initial function that binds a [TileMapLayer] to the navigation class
func set_current_map(map : TileMapLayer):
	current_map = map
	if current_map != null:
		astar.clear()
		add_all_point()
	print("there are " + str(astar.get_point_count()) + " points in this map")

## Adds and connects all cells in the [TileMapLayer]
func add_all_point(): 
	var all_used_cells = current_map.get_used_cells()
	for cell in all_used_cells:
		var next_id := astar.get_available_point_id()

		if not get_cell_custom_data(cell, "prevent_click"):
			astar.add_point(next_id, cell)

	for point_id in astar.get_point_ids():
		var pos = astar.get_point_position(point_id)
		var all_possible_neighbors = current_map.get_surrounding_cells(pos)
		var valid_neighbor = []
		for neighbor in all_possible_neighbors:
			if current_map.get_cell_source_id(neighbor) != -1 and not get_cell_custom_data(neighbor, "prevent_click"): #if the cell is not empty
				valid_neighbor.append(neighbor)
		for neighbor in valid_neighbor:
			var neighbor_id = astar.get_closest_point(neighbor)
			astar.connect_points(point_id, neighbor_id)

## Set the [member weight_scale] of all tiles in the data layer with [param layer_name] that meet [param condition] to [param new_weight]
func set_weight_of_layer(layer_name: String, condition: Variant, new_weight: float) -> void:
	var all_point_id = astar.get_point_ids()
	for id in all_point_id:
		var tile = id_to_tile(id)
		if get_cell_custom_data(tile, layer_name) == condition:
			astar.set_point_weight_scale(id, new_weight)
	
#general process of converting global position to a cell position
	#1. convert global position to map node's local
	#2. convert map node's local to map coordinates
	#3. use the map coordinate to locate the closest cell in astar
	#do the other way around to convert cell position to global position

## Returns the global position of a cell position
func cell_to_global(cell_pos : Vector2i) -> Vector2:
	return current_map.to_global(current_map.map_to_local(cell_pos))

## Returns the cell position of a global position; returns [code]Vector2i(-999, 999)[/code] if no valid cell is found.
func global_to_cell(global_pos : Vector2) -> Vector2i: #returns local cell position
	var local_map_pos := current_map.local_to_map(current_map.to_local(global_pos))
	var closest_point_id = astar.get_closest_point(local_map_pos)
	var closest_cell: Vector2i = astar.get_point_position(closest_point_id)
	if local_map_pos != closest_cell: #prevents returning nonexistent cell
		return Vector2i(-999, -999)
	return closest_cell 

## Returns the cell position that is closest to a given global position; similar to [method HexUtil.global_to_cell()] but always returns a valid cell position.
func get_closest_cell_by_global_pos(global_pos : Vector2) -> Vector2i:
	var local_map_pos := current_map.local_to_map(current_map.to_local(global_pos))
	var closest_point_id = astar.get_closest_point(local_map_pos)
	var closest_cell: Vector2i = astar.get_point_position(closest_point_id)
	return closest_cell

func get_cell_custom_data(cell_pos: Vector2i, data_name: String):
	var data = current_map.get_cell_tile_data(cell_pos)
	if data:
		return data.get_custom_data(data_name)
	else:
		return

## Returns an array of cell positions from start to goal
func get_navi_path(start_pos : Vector2i, end_pos : Vector2i) -> PackedVector2Array:
	var start_id = tile_to_id(start_pos)
	var goal_id = tile_to_id(end_pos)
	var path_taken = astar.get_point_path(start_id, goal_id)
	return to_local(path_taken)
	
func get_waypoints_path(waypoints: Array[Vector2]):
	var complete_path: Array[Vector2] = []
	
	for i in range(waypoints.size() - 1):
		var start = waypoints[i]
		var end = waypoints[i + 1]
		var segment_path = get_navi_path(start, end)
		
		if i == 0:
			# For first segment, add all points
			complete_path.append_array(segment_path)
		else:
			# For subsequent segments, skip the first point to avoid duplicates
			for j in range(1, segment_path.size()):
				complete_path.append(segment_path[j])
				
	return complete_path

func to_local(path: Array):
	return path.map(func(point): return current_map.map_to_local(Vector2i(point)))

## Use a tile position to get the id for AStar usage
func tile_to_id(pos: Vector2i) -> int: 
	#assuming that all available tiles are already mapped in astar
	if current_map.get_cell_source_id(pos) != -1:
		return astar.get_closest_point(pos)
	else: return -1

## Use an AStar point ID to get the point's tile position
func id_to_tile(id: int) -> Vector2i:
	if astar.has_point(id):
		return astar.get_point_position(id)
	return Vector2i(-1, -1)

func get_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	var all_points = get_navi_path(pos1, pos2)
	return all_points.size() - 1 #excluding the first point

## Returns all neighbor cells of a given cell at [param start_pos] within [param range].
func get_all_neighbors_in_range(start_pos: Vector2i, hex_range: int, max_weight: float = 1) -> Array[Vector2i]:
	#returns an array of cell ID
	#employs a depth first search
	var all_neighbors_id : Array[int] = []
	var starting_cell_id = tile_to_id(start_pos)
	_dfs(hex_range, starting_cell_id, starting_cell_id, all_neighbors_id, max_weight)
	var all_neighbors_pos = all_neighbors_id.map(id_to_tile)
	var answer: Array[Vector2i]
	answer.assign(all_neighbors_pos)
	return answer
	
func _dfs(k : int, node_id : int, parent_id : int, solution_arr : Array, max_weight: float): #helper recursive function
	#godot seems to pass array by reference by default
	if k < 0 or node_id == -1:
		return
	if astar.get_point_weight_scale(node_id) > max_weight:
		return
	if !solution_arr.has(node_id):
		solution_arr.append(node_id)
	for neighbor_pos in current_map.get_surrounding_cells(astar.get_point_position(node_id)):
		var neighbor_id = tile_to_id(neighbor_pos)
		if neighbor_id != parent_id:
			_dfs(k-1, neighbor_id, node_id, solution_arr, max_weight)

## Return all tiles with [param value] in the custom data value with name [param custom_data_name]
func get_all_tile_with_layer(custom_data_name: String, value: Variant) -> Array[Vector2i]:
	var valid_tiles: Array[Vector2i] = []
	var all_point_id = astar.get_point_ids()
	for id in all_point_id:
		var tile = id_to_tile(id)
		if get_cell_custom_data(tile, custom_data_name) == value:
			valid_tiles.append(tile)
	return valid_tiles

func get_front_line_points() -> Dictionary:
	var players_territories = TerritoryManager.territories
	var players_frontlines: Dictionary = {}
	
	var players_territories_flipped: Dictionary = {}

	for pos in players_territories.keys():
		var player_id = players_territories[pos]
		if players_territories_flipped.has(player_id):
			players_territories_flipped[player_id].append(pos)
		else:
			players_territories_flipped[player_id] = [pos]
	
	for player_id in players_territories_flipped.keys():
		var player_territory = players_territories_flipped[player_id]
		var frontline_points: Array[Vector2] = []
		
		for pos in player_territory:
			var all_possible_neighbors = current_map.get_surrounding_cells(pos)
			
			for neighbor in all_possible_neighbors:
				var does_cell_exist = current_map.get_cell_source_id(neighbor) != -1
				var is_cell_clickable = not get_cell_custom_data(neighbor, "prevent_click")
				var is_already_owned_cell = player_territory.has(neighbor)

				if  does_cell_exist and is_cell_clickable and not is_already_owned_cell: #if the cell is not empty
					var direction: Vector2 = pos - neighbor
					var global_pos = cell_to_global(pos)
					var point1 = Vector2.ZERO
					var point2 = Vector2.ZERO
					
					var is_even_row = pos.y % 2 == 0
					
					match direction:
						Vector2(1, 0): # Left neighbor
							point1 = global_pos - Vector2(cell_size_x / 2, cell_size_y / 4)
							point2 = global_pos - Vector2(cell_size_x / 2, -cell_size_y / 4)
						Vector2(-1, 0): # Right neighbor
							point1 = global_pos + Vector2(cell_size_x / 2, -cell_size_y / 4)
							point2 = global_pos + Vector2(cell_size_x / 2, cell_size_y / 4)
						Vector2(0, 1): # Top-left neighbor
							if is_even_row:
								point1 = global_pos + Vector2(0, -cell_size_y / 2)
								point2 = global_pos + Vector2(cell_size_x / 2, -cell_size_y / 4)
							else:
								point1 = global_pos + Vector2(-cell_size_x / 2, -cell_size_y / 4)
								point2 = global_pos + Vector2(0, -cell_size_y / 2)
						Vector2(0, -1): # Bottom-right neighbor
							if is_even_row:
								point1 = global_pos + Vector2(0, cell_size_y / 2)
								point2 = global_pos + Vector2(cell_size_x / 2, cell_size_y / 4)
							else:
								point1 = global_pos + Vector2(-cell_size_x / 2, cell_size_y / 4)
								point2 = global_pos + Vector2(0, cell_size_y / 2)
						Vector2(1, 1): # Top-right neighbor
							point1 = global_pos + Vector2(0, -cell_size_y / 2)
							point2 = global_pos + Vector2(-cell_size_x / 2, -cell_size_y / 4)
						Vector2(1, -1): # Bottom-left neighbor 
							point1 = global_pos + Vector2(-cell_size_x / 2, cell_size_y / 4)
							point2 = global_pos + Vector2(0, cell_size_y / 2)
						Vector2(-1, 1): # Already handled correctly
							point1 = global_pos + Vector2(0, -cell_size_y / 2)
							point2 = global_pos + Vector2(cell_size_x / 2, -cell_size_y / 4)
						Vector2(-1, -1): # Already handled correctly
							point1 = global_pos + Vector2(0, cell_size_y / 2)
							point2 = global_pos + Vector2(cell_size_x / 2, cell_size_y / 4)

					frontline_points.append(point1)
					frontline_points.append(point2)
		
		players_frontlines[player_id] = frontline_points
	
	return players_frontlines

func get_next_hex():
	var players_territories = TerritoryManager.territories
	var player_territory = []
	
	for pos in players_territories.keys():
		var player_id = players_territories[pos]
		
		if player_id == NetworkManager.player_id:
			player_territory.append(pos)
			
	# If player has no territory, return invalid position
	if player_territory.is_empty():
		return Vector2i(-999, -999)
	
	# Find all adjacent cells that can be conquered
	var conquest_candidates = []
	
	for owned_pos in player_territory:
		var all_possible_neighbors = current_map.get_surrounding_cells(owned_pos)
		
		for neighbor in all_possible_neighbors:
			var does_cell_exist = current_map.get_cell_source_id(neighbor) != -1
			var is_cell_clickable = not get_cell_custom_data(neighbor, "prevent_click")
			var is_already_taken = players_territories.has(neighbor)
			
			# If cell exists, is clickable, and not already owned by anyone
			if does_cell_exist and is_cell_clickable and not is_already_taken:
				if not conquest_candidates.has(neighbor):
					conquest_candidates.append(neighbor)
	
	# If no conquest candidates available, return invalid position
	if conquest_candidates.is_empty():
		return Vector2i(-999, -999)
	
	# Return the first available candidate
	return conquest_candidates[0]
