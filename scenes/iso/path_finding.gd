extends RefCounted
class_name PathfindingUtils

# Pathfinding utilities for grid-based tilemaps using A* algorithm

# Direction vectors for 4-directional movement (up, right, down, left)
const DIRECTIONS_4 = [
	Vector2i(0, -1),  # Up
	Vector2i(1, 0),   # Right
	Vector2i(0, 1),   # Down
	Vector2i(-1, 0)   # Left
]

# Direction vectors for 8-directional movement (includes diagonals)
const DIRECTIONS_8 = [
	Vector2i(0, -1),   # Up
	Vector2i(1, -1),   # Up-Right
	Vector2i(1, 0),    # Right
	Vector2i(1, 1),    # Down-Right
	Vector2i(0, 1),    # Down
	Vector2i(-1, 1),   # Down-Left
	Vector2i(-1, 0),   # Left
	Vector2i(-1, -1)   # Up-Left
]

# Node class for A* pathfinding
class PathNode:
	var position: Vector2i
	var g_cost: float = 0.0  # Distance from start
	var h_cost: float = 0.0  # Heuristic distance to end
	var f_cost: float = 0.0  # Total cost (g + h)
	var parent: PathNode = null
	
	func _init(pos: Vector2i):
		position = pos
	
	func calculate_f_cost():
		f_cost = g_cost + h_cost

# Configuration for pathfinding
var allow_diagonal: bool = false
var diagonal_cost: float = 1.414  # sqrt(2)
var straight_cost: float = 1.0
var tilemap: TileMapLayer = null
var collision_layer: int = 0
var collision_source_id: int = 0

# Initialize with tilemap reference
func setup(tm: TileMapLayer, layer: int = 0, source_id: int = 0):
	tilemap = tm
	collision_layer = layer
	collision_source_id = source_id

# Main pathfinding function - finds path from start to end coordinates
func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not tilemap:
		push_error("Tilemap not set! Call setup() first.")
		return []
	
	if not is_walkable(start) or not is_walkable(end):
		return []
	
	var open_list: Array[PathNode] = []
	var closed_list: Dictionary = {}
	var start_node = PathNode.new(start)
	
	open_list.append(start_node)
	
	while open_list.size() > 0:
		# Find node with lowest f_cost in open list
		var current_node = get_lowest_f_cost_node(open_list)
		open_list.erase(current_node)
		closed_list[current_node.position] = current_node
		
		# Check if we reached the target
		if current_node.position == end:
			return reconstruct_path(current_node)
		
		# Check all neighbors
		var directions = DIRECTIONS_8 if allow_diagonal else DIRECTIONS_4
		for direction in directions:
			var neighbor_pos = current_node.position + direction
			
			# Skip if neighbor is in closed list or not walkable
			if closed_list.has(neighbor_pos) or not is_walkable(neighbor_pos):
				continue
			
			# Calculate movement cost
			var is_diagonal_move = abs(direction.x) + abs(direction.y) == 2
			var movement_cost = diagonal_cost if is_diagonal_move else straight_cost
			var tentative_g_cost = current_node.g_cost + movement_cost
			
			# Find existing node in open list or create new one
			var neighbor_node = find_node_in_list(open_list, neighbor_pos)
			if not neighbor_node:
				neighbor_node = PathNode.new(neighbor_pos)
				open_list.append(neighbor_node)
			elif tentative_g_cost >= neighbor_node.g_cost:
				continue  # This path is not better
			
			# Update neighbor node
			neighbor_node.parent = current_node
			neighbor_node.g_cost = tentative_g_cost
			neighbor_node.h_cost = calculate_heuristic(neighbor_pos, end)
			neighbor_node.calculate_f_cost()
	
	# No path found
	return []

# Check if a tile position is walkable (not blocked by collision)
func is_walkable(pos: Vector2i) -> bool:
	if not tilemap:
		return false
	
	# Check if position is within tilemap bounds
	var used_rect = tilemap.get_used_rect()
	if not used_rect.has_point(pos):
		return false
	
	# Get tile data at position
	var tile_data = tilemap.get_cell_tile_data(pos)
	if not tile_data:
		return true  # No tile = walkable
	
	# Check if tile has collision
	return not tile_data.get_collision_polygons_count(collision_source_id) > 0

# Calculate heuristic distance (Manhattan distance for 4-dir, Euclidean for 8-dir)
func calculate_heuristic(from: Vector2i, to: Vector2i) -> float:
	if allow_diagonal:
		# Euclidean distance for diagonal movement
		var dx = abs(to.x - from.x)
		var dy = abs(to.y - from.y)
		return sqrt(dx * dx + dy * dy)
	else:
		# Manhattan distance for 4-directional movement
		return abs(to.x - from.x) + abs(to.y - from.y)

# Find node with lowest f_cost in the list
func get_lowest_f_cost_node(node_list: Array[PathNode]) -> PathNode:
	var lowest_node = node_list[0]
	for node in node_list:
		if node.f_cost < lowest_node.f_cost:
			lowest_node = node
	return lowest_node

# Find a node with specific position in the list
func find_node_in_list(node_list: Array[PathNode], pos: Vector2i) -> PathNode:
	for node in node_list:
		if node.position == pos:
			return node
	return null

# Reconstruct the path from end node back to start
func reconstruct_path(end_node: PathNode) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current_node = end_node
	
	while current_node != null:
		path.push_front(current_node.position)
		current_node = current_node.parent
	
	return path

# Get neighbors of a position (useful for other algorithms)
func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = DIRECTIONS_8 if allow_diagonal else DIRECTIONS_4
	
	for direction in directions:
		var neighbor_pos = pos + direction
		if is_walkable(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

# Calculate distance between two points
func calculate_distance(from: Vector2i, to: Vector2i) -> float:
	return calculate_heuristic(from, to)

# Check if there's a direct line of sight between two points
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var diff = to - from
	var steps = max(abs(diff.x), abs(diff.y))
	
	if steps == 0:
		return true
	
	var step_x = float(diff.x) / steps
	var step_y = float(diff.y) / steps
	
	for i in range(1, steps):
		var check_pos = Vector2i(
			int(from.x + step_x * i),
			int(from.y + step_y * i)
		)
		if not is_walkable(check_pos):
			return false
	
	return true

# Smooth a path by removing unnecessary waypoints
func smooth_path(path: Array[Vector2i]) -> Array[Vector2i]:
	if path.size() <= 2:
		return path
	
	var smoothed: Array[Vector2i] = [path[0]]
	var current_index = 0
	
	while current_index < path.size() - 1:
		var farthest_visible = current_index + 1
		
		# Find the farthest point we can see from current position
		for i in range(current_index + 2, path.size()):
			if has_line_of_sight(path[current_index], path[i]):
				farthest_visible = i
			else:
				break
		
		smoothed.append(path[farthest_visible])
		current_index = farthest_visible
	
	return smoothed

# Set movement options
func set_diagonal_movement(enabled: bool, diag_cost: float = 1.414):
	allow_diagonal = enabled
	diagonal_cost = diag_cost

# Utility function to convert world position to grid position
func world_to_grid(world_pos: Vector2) -> Vector2i:
	if tilemap:
		return tilemap.local_to_map(world_pos)
	return Vector2i(int(world_pos.x), int(world_pos.y))

# Utility function to convert grid position to world position
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if tilemap:
		return tilemap.map_to_local(grid_pos)
	return Vector2(grid_pos.x, grid_pos.y)
