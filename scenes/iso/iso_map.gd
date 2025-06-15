extends TileMapLayer

var pathfinder = PathfindingUtils.new()

var start_point = null
var end_point = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pathfinder.setup(self, 0, 0) 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		var follower = get_node_or_null("../../Path2D/PathFollow2D")
		if follower:
			follower.progress += 50 * delta  # Adjust speed
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var global_clicked = get_global_mouse_position()
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
	var path2d = Path2D.new()
	var curve = Curve2D.new()
	path2d.name = "Path2D"
	$"../..".add_child(path2d)
	# Convert each tile (Vector2i or Vector2) into a local position
	for tile in path:
		var point = map_to_local(Vector2i(tile))  # Ensure it's Vector2i for TileMap
		curve.add_point(point)

	# Set curve
	path2d.curve = curve

	# Reset follower
	var follower = PathFollow2D.new()
	follower.progress = 0
	follower.progress_ratio = 0.0
	follower.name = 'PathFollow2D'
	
	# Reset the sprite visibility
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.scale = Vector2(0.2, 0.2)
	sprite.z_index = 100
	#print("Curve point count:", curve.get_point_count())
	
	follower.add_child(sprite)
	
	path2d.add_child(follower)
