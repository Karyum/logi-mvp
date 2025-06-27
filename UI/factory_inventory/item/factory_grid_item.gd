extends Node2D
class_name FactoryGridItem

@onready var item_label: Label = $Panel/NameLabel


var item_id: int
var item_grid := []
var item_name := ''
var selected = false
var grid_anchor = null
var panel_size = Vector2.ZERO
var rotated := false

func _process(delta: float) -> void:
	if selected:
		global_position = lerp(global_position, get_global_mouse_position(), 100 * delta)
		
		
	
func load_item(factory_type: String, new_item_id: int) -> void:
	var item_data = DataHandler.find_factory_item(factory_type, new_item_id)
	
	item_id = new_item_id
	item_grid = Array(item_data['grid']).duplicate()
	item_name = item_data['name']
	
	panel_size = calculate_grid_size(item_grid)
	$Panel.size = panel_size
	item_label.text = item_name
	

func calculate_grid_size(coordinates: Array) -> Vector2:
	if coordinates.is_empty():
		return Vector2.ZERO
	
	var max_x = 0
	var max_y = 0
	
	for coord_str in coordinates:
		var parts = coord_str.split(",")
		var x = int(parts[0])
		var y = int(parts[1])
		
		max_x = max(max_x, x)
		max_y = max(max_y, y)
	
	# Add 1 because coordinates are 0-based, then multiply by cell size
	var width = (max_x + 1) * 49
	var height = (max_y + 1) * 49
	
	return Vector2(width, height)

func rotate_item():
	if rotated:
		rotation_degrees = 0
		# Rotate coordinates back (counter-clockwise)
		for i in range(item_grid.size()):
			var xy = item_grid[i].split(',')
			var temp_x = int(xy[0])
			var new_x = -int(xy[1])
			var new_y = temp_x
			item_grid[i] = str(new_x) + "," + str(new_y)
		
		$Panel.position += Vector2(panel_size.y + 20, 0)
		rotated = false
	else:
		rotation_degrees = 90
		# Rotate coordinates forward (clockwise)
		for i in range(item_grid.size()):
			var xy = item_grid[i].split(',')
			var temp_y = int(xy[1])
			var new_x = temp_y
			var new_y = -int(xy[0])
			item_grid[i] = str(new_x) + "," + str(new_y)
		
		rotated = true
		$Panel.position -= Vector2(panel_size.y + 20, 0)

func _snap_to(destination):
	var tween = get_tree().create_tween()
	#separate cases to avoid snapping errors
	if rotation_degrees == 0:
		destination += Vector2(20 ,20)
	else:
		var temp_xy_switch = Vector2(panel_size.y - 20,panel_size.y + 40)
		destination += temp_xy_switch

	var style_box = StyleBoxFlat.new()
	style_box.set_border_width_all(0)
	style_box.bg_color = Color(Color.DARK_GRAY, 1.0)
	$Panel.add_theme_stylebox_override("panel", style_box)

	tween.tween_property(self, "global_position", destination, 0.15).set_trans(Tween.TRANS_SINE)
	selected = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func picked_up(): 
	var style_box = StyleBoxFlat.new()
	style_box.set_border_width_all(1)
	style_box.border_color = Color.BLACK
	style_box.bg_color = Color(Color.DARK_GRAY, 0.3)
	$Panel.add_theme_stylebox_override("panel", style_box)
