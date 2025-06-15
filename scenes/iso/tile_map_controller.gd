extends TileMap

var pathfinder = PathfindingUtils.new()

var start_point = null
var end_point = null

func _ready():
	pathfinder.setup(self, 0, 0) 

func _process(delta):
	var follower = $Path2D/PathFollow2D
	follower.progress += 50 * delta  # Adjust speed

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var global_clicked = event.position
			var pos_clicked = local_to_map(to_local(global_clicked))
			
			if not start_point:
				start_point = pos_clicked
			elif not end_point:
				end_point = pos_clicked
				var path = pathfinder.find_path(start_point, end_point)
				build_path2d_from_tiles(path)
				start_point = null
				end_point = null
				
func build_path2d_from_tiles(path: Array) -> void:
	var path2d = $Path2D
	var curve = Curve2D.new()

	# Convert each tile (Vector2i or Vector2) into a local position
	for tile in path:
		var point = map_to_local(Vector2i(tile))  # Ensure it's Vector2i for TileMap
		curve.add_point(point)

	# Set curve
	path2d.curve = curve

	# Reset follower
	var follower = $Path2D/PathFollow2D
	follower.progress = 0
	follower.progress_ratio = 0.0

	# Reset the sprite visibility
	var sprite = $Path2D/PathFollow2D/Sprite2D
	sprite.visible = true
	

func _draw():
	var used_rect = get_used_rect()
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			if get_cell_source_id(0, Vector2i(x, y)) != -1:
				var world_pos = map_to_local(Vector2i(x, y))
				draw_string(ThemeDB.fallback_font, world_pos, str(x, ",", y))
