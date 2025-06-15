extends Node2D

#signal truck_reached_destination

@onready var follower = $Path/PathFollow2D
@onready var sprite = $Path/PathFollow2D/Sprite2D
var start_moving: bool = false

func _process(delta):
	if start_moving:
		follower.progress += 50 * delta 
	#$Path/PathFollow2D/Sprite2D.rotation = follower.rotation
	
func create_route(path: Array):
	var curve = Curve2D.new()
	# Convert each tile (Vector2i or Vector2) into a local position
	for point in path:
		curve.add_point(point)
		
	$Path.curve = curve
	follower.progress = 0
	start_moving = true
