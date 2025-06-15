class_name HexGridUtils
extends RefCounted

# Hex grid directions for flat-top hexagons (most common)
# Directions: NE, E, SE, SW, W, NW
const HEX_DIRECTIONS = [
	Vector2i(1, -1),  # NE
	Vector2i(1, 0),   # E
	Vector2i(0, 1),   # SE
	Vector2i(-1, 1),  # SW
	Vector2i(-1, 0),  # W
	Vector2i(0, -1)   # NW
]

# Reference to the tilemap
var tilemap: TileMapLayer

func _init(p_tilemap: TileMapLayer):
	tilemap = p_tilemap

# Get all valid neighboring hex coordinates
func get_hex_neighbors(hex_coord: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []

	for direction in HEX_DIRECTIONS:
		var neighbor = hex_coord + direction
		if is_valid_tile(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

# Calculate hex distance between two coordinates
func hex_distance(a: Vector2i, b: Vector2i) -> int:
	# Convert to cube coordinates for easier distance calculation
	var a_cube = axial_to_cube(a)
	var b_cube = axial_to_cube(b)
	
	return (abs(a_cube.x - b_cube.x) + abs(a_cube.y - b_cube.y) + abs(a_cube.z - b_cube.z)) / 2

# Convert axial coordinates (q, r) to cube coordinates (x, y, z)
func axial_to_cube(axial: Vector2i) -> Vector3i:
	var x = axial.x
	var z = axial.y
	var y = -x - z
	return Vector3i(x, y, z)

# Convert cube coordinates back to axial
func cube_to_axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.z)

# Check if a tile position is valid (placeholder - customize as needed)
func is_valid_tile(hex_coord: Vector2i) -> bool:
	# TODO: Implement your validation logic here
	# For now, just check if the tile exists in the tilemap
	#var tile_data = tilemap.get_cell_tile_data(hex_coord)
	return true

# Get the cost of moving to a specific tile (for weighted pathfinding)
func get_tile_cost(hex_coord: Vector2i) -> float:
	# Default cost is 1.0 - override this based on your tile types
	if not is_valid_tile(hex_coord):
		return INF
	
	# You can add custom logic here based on tile types
	# Example: different terrain types have different costs
	# var tile_data = tilemap.get_cell_tile_data(0, hex_coord)
	# if tile_data:
	#     match tile_data.get_custom_data("terrain_type"):
	#         "water": return 2.0
	#         "mountain": return 3.0
	#         "road": return 0.5
	
	return 1.0

# Helper class for A* priority queue
class AStarNode:
	var position: Vector2i
	var f_score: float
	var g_score: float
	
	func _init(pos: Vector2i, f: float, g: float):
		position = pos
		f_score = f
		g_score = g

# Improved A* pathfinding for hex grids with proper priority queue
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not is_valid_tile(start) or not is_valid_tile(goal):
		print("Invalid start or goal position")
		return []
	
	if start == goal:
		return [start]
	
	# A* algorithm implementation with priority queue
	var open_set: Array[AStarNode] = []
	var open_set_lookup: Dictionary = {}  # For fast lookup
	var closed_set: Dictionary = {}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {}
	
	# Initialize start node
	var start_g = 0.0
	var start_f = start_g + hex_distance(start, goal)
	var start_node = AStarNode.new(start, start_f, start_g)
	
	open_set.append(start_node)
	open_set_lookup[start] = start_node
	g_score[start] = start_g
	
	while open_set.size() > 0:
		# Find and remove node with lowest f_score (proper priority queue behavior)
		var current_idx = 0
		var current_f = open_set[0].f_score
		
		for i in range(1, open_set.size()):
			if open_set[i].f_score < current_f:
				current_idx = i
				current_f = open_set[i].f_score
		
		var current_node = open_set[current_idx]
		var current = current_node.position
		
		# Remove from open set
		open_set.remove_at(current_idx)
		open_set_lookup.erase(current)
		closed_set[current] = true
		
		# Check if we reached the goal
		if current == goal:
			return reconstruct_path(came_from, current)
		
		# Explore neighbors
		for neighbor in get_hex_neighbors(current):
			# Skip if already processed
			if neighbor in closed_set:
				continue
			
			var tentative_g = g_score.get(current, INF) + get_tile_cost(neighbor)
			
			# Check if this path to neighbor is better than any previous one
			var neighbor_in_open = neighbor in open_set_lookup
			var current_neighbor_g = g_score.get(neighbor, INF)
			
			if tentative_g < current_neighbor_g:
				# This path is the best until now. Record it!
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				var neighbor_f = tentative_g + hex_distance(neighbor, goal)
				
				if neighbor_in_open:
					# Update existing node in open set
					var neighbor_node = open_set_lookup[neighbor]
					neighbor_node.f_score = neighbor_f
					neighbor_node.g_score = tentative_g
				else:
					# Add new node to open set
					var neighbor_node = AStarNode.new(neighbor, neighbor_f, tentative_g)
					open_set.append(neighbor_node)
					open_set_lookup[neighbor] = neighbor_node
	
	# No path found
	print("No path found from ", start, " to ", goal)
	return []

# Reconstruct the path from A* result
func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	
	while current in came_from:
		current = came_from[current]
		path.push_front(current)
	
	return path

# Get all tiles within a certain range
func get_tiles_in_range(center: Vector2i, range: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	
	for q in range(-range, range + 1):
		var r1 = max(-range, -q - range)
		var r2 = min(range, -q + range)
		
		for r in range(r1, r2 + 1):
			var hex = Vector2i(center.x + q, center.y + r)
			if is_valid_tile(hex):
				tiles.append(hex)
	
	return tiles

# Get tiles in a ring at specific distance
func get_tiles_in_ring(center: Vector2i, radius: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	
	if radius == 0:
		if is_valid_tile(center):
			return [center]
		else:
			return []
	
	# Start at one corner of the ring
	var hex = center + Vector2i(0, -radius)
	
	# Walk around the ring
	for direction_idx in range(6):
		for step in range(radius):
			if is_valid_tile(hex):
				tiles.append(hex)
			hex += HEX_DIRECTIONS[direction_idx]
	
	return tiles

# Convert hex coordinates to world position (for rendering/positioning)
func hex_to_world(hex_coord: Vector2i, hex_size: float = 64.0) -> Vector2:
	# For flat-top hexagons
	var x = hex_size * (3.0/2.0 * hex_coord.x)
	var y = hex_size * (sqrt(3.0)/2.0 * hex_coord.x + sqrt(3.0) * hex_coord.y)
	
	return Vector2(x, y)

# Convert world position to hex coordinates
func world_to_hex(world_pos: Vector2, hex_size: float = 64.0) -> Vector2i:
	# For flat-top hexagons
	var q = (2.0/3.0 * world_pos.x) / hex_size
	var r = (-1.0/3.0 * world_pos.x + sqrt(3.0)/3.0 * world_pos.y) / hex_size
	
	return round_hex(Vector2(q, r))

# Round fractional hex coordinates to nearest hex
func round_hex(hex: Vector2) -> Vector2i:
	var cube = Vector3(hex.x, -hex.x - hex.y, hex.y)
	
	var rx = round(cube.x)
	var ry = round(cube.y)
	var rz = round(cube.z)
	
	var x_diff = abs(rx - cube.x)
	var y_diff = abs(ry - cube.y)
	var z_diff = abs(rz - cube.z)
	
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	
	return Vector2i(int(rx), int(rz))

# Line of sight check between two hex coordinates
func has_line_of_sight(start: Vector2i, end: Vector2i) -> bool:
	var path_tiles = get_line_between_hexes(start, end)
	
	for tile in path_tiles:
		if not is_valid_tile(tile):
			return false
		# Add additional checks here if needed (e.g., blocking terrain)
	
	return true

# Get all hexes on a line between two points
func get_line_between_hexes(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var distance = hex_distance(start, end)
	var results: Array[Vector2i] = []
	
	if distance == 0:
		return [start]
	
	for i in range(distance + 1):
		var t = float(i) / float(distance)
		var lerped = hex_lerp(Vector2(start.x, start.y), Vector2(end.x, end.y), t)
		results.append(round_hex(lerped))
	
	return results

# Linear interpolation between two hex coordinates
func hex_lerp(a: Vector2, b: Vector2, t: float) -> Vector2:
	return Vector2(
		a.x + (b.x - a.x) * t,
		a.y + (b.y - a.y) * t
	)
	
func find_path_from_array(waypoints: Array[Vector2i]) -> Array[Vector2i]:
	if waypoints.is_empty():
		print("No waypoints provided")
		return []
	
	if waypoints.size() == 1:
		return waypoints
	
	var complete_path: Array[Vector2i] = []
	
	# Find path between each consecutive pair of waypoints
	for i in range(waypoints.size() - 1):
		var start = waypoints[i]
		var end = waypoints[i + 1]
		
		print("Finding path from ", start, " to ", end)
		var segment_path = find_path(start, end)
		print("Segment path: ", segment_path)
		
		if segment_path.is_empty():
			print("No path found between waypoint ", i, " (", start, ") and waypoint ", i + 1, " (", end, ")")
			return []  # Return empty if any segment fails
		
		# Add the segment to complete path
		if i == 0:
			# For first segment, add all points
			complete_path.append_array(segment_path)
		else:
			# For subsequent segments, skip the first point to avoid duplicates
			for j in range(1, segment_path.size()):
				complete_path.append(segment_path[j])
		
		print("Complete path so far: ", complete_path)
	
	# Remove non-consecutive duplicates by finding backtrack points
	var cleaned_path: Array[Vector2i] = []
	var used_positions: Dictionary = {}
	
	for i in range(complete_path.size()):
		var current_pos = complete_path[i]
		
		if current_pos in used_positions:
			# We've been here before - this is a backtrack situation
			# Remove everything after the first occurrence of this position
			var first_occurrence = used_positions[current_pos]
			cleaned_path = cleaned_path.slice(0, first_occurrence + 1)
			used_positions.clear()
			
			# Rebuild the used_positions dictionary
			for j in range(cleaned_path.size()):
				used_positions[cleaned_path[j]] = j
		else:
			cleaned_path.append(current_pos)
			used_positions[current_pos] = cleaned_path.size() - 1
	
	print("Final cleaned path: ", cleaned_path)
	return cleaned_path

# Alternative waypoint pathfinding that's smarter about duplicates
func find_path_from_array_optimized(waypoints: Array[Vector2i]) -> Array[Vector2i]:
	if waypoints.is_empty():
		print("No waypoints provided")
		return []
	
	if waypoints.size() == 1:
		return waypoints
	
	# First, get all individual segments
	var all_segments: Array[Array] = []
	
	for i in range(waypoints.size() - 1):
		var start = waypoints[i]
		var end = waypoints[i + 1]
		
		var segment_path = find_path(start, end)
		
		if segment_path.is_empty():
			print("No path found between waypoint ", i, " (", start, ") and waypoint ", i + 1, " (", end, ")")
			return []
		
		all_segments.append(segment_path)
	
	# Now intelligently combine segments
	var complete_path: Array[Vector2i] = []
	
	for i in range(all_segments.size()):
		var segment = all_segments[i] as Array[Vector2i]
		
		if i == 0:
			# First segment - add everything
			complete_path.append_array(segment)
		else:
			# Find where this segment should connect to the previous path
			var segment_start = segment[0]
			var connection_point = -1
			
			# Look backwards through the current path to find the connection point
			for j in range(complete_path.size() - 1, -1, -1):
				if complete_path[j] == segment_start:
					connection_point = j
					break
			
			if connection_point >= 0:
				# Remove everything after the connection point and add the new segment
				complete_path = complete_path.slice(0, connection_point + 1)
				# Add the rest of the segment (skipping the first point to avoid duplicate)
				for k in range(1, segment.size()):
					complete_path.append(segment[k])
			else:
				# No connection found, just append (skipping first to avoid duplicate with end of previous segment)
				for k in range(1, segment.size()):
					complete_path.append(segment[k])
	
	return complete_path
