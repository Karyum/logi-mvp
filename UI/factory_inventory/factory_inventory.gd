extends Control
class_name FactoryInventory

@onready var slot_scene = preload("res://UI/factory_inventory/slot/slot.tscn")
@onready var item_scene = preload("res://UI/factory_inventory/item/factory_grid_item.tscn")
@onready var grid_container = $ColorRect/HBoxContainer/MarginContainer/VBoxContainer/GridContainer
@onready var flow_container = $ColorRect/HBoxContainer/HFlowContainer
@onready var col_count = grid_container.columns


@export var grid_size := 32
@export var factory_type := 'steel'

var grid_array : Array[FactoryGridSlot] = []
var item_held: FactoryGridItem
var current_slot: FactoryGridSlot
var item_anchor: Vector2
var can_place = false

func create_items_list():
	for child in flow_container.get_children():
		flow_container.remove_child(child)
	print(1,factory_type)
	var items = DataHandler.fetch_factory_items(factory_type)
	#
	for item in items:
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_bottom", 5)
		var new_button = Button.new()
		new_button.pressed.connect(func(): _on_button_pressed(item['item_id']))
		new_button.text = item['name']
		margin.add_child(new_button)
		flow_container.add_child(margin)

		
func open_inventory(factory_data: Factory):
	factory_type = factory_data.factory_type.to_lower()
	grid_size = factory_data.grid_size
	visible = true
	
	# Reset/clear existing grid
	clear_grid()  # Reset visual states
	
	# Remove existing slots from grid_container and clear the array
	for slot in grid_array:
		if slot and is_instance_valid(slot):
			grid_container.remove_child(slot)
			slot.queue_free()
	
	grid_array.clear()
	
	for i in range(factory_data.grid_size):
		create_slot()
		
	create_items_list()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not self.get_global_rect().has_point(get_viewport().get_mouse_position()):
			self.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if item_held:
		if Input.is_action_just_pressed("mouse_rightclick"):
			rotate_item()
		if Input.is_action_just_pressed("mouse_leftclick"):
			if grid_container.get_global_rect().has_point(get_global_mouse_position()):
				place_item()
	else:
		if Input.is_action_just_pressed("mouse_leftclick"):
			if grid_container.get_global_rect().has_point(get_global_mouse_position()):
				pick_item()


func create_slot():
	var new_slot = slot_scene.instantiate() as FactoryGridSlot
	new_slot.slot_id = grid_array.size()
	grid_array.append(new_slot)
	grid_container.add_child(new_slot)
	
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)
	
	
func _on_slot_mouse_entered(slot: FactoryGridSlot):
	current_slot = slot
	item_anchor = Vector2(100000, 100000)
	
	if item_held:
		clear_grid()
		check_slot_availability(current_slot)
		set_grids.call_deferred(current_slot)
	
func _on_slot_mouse_exited(_slot: FactoryGridSlot):
	pass
	
func rotate_item():
	item_held.rotate_item()
	clear_grid()
	if current_slot:
		_on_slot_mouse_entered(current_slot)

func check_slot_availability(slot: FactoryGridSlot):
	for grid_coord in item_held.item_grid:
		var xy = grid_coord.split(',')
		var grid_to_check = slot.slot_id + int(xy[0]) + int(xy[1]) * col_count
		var line_switch_check = slot.slot_id % col_count + int(xy[0])
		
		if line_switch_check < 0 or line_switch_check >= col_count:
			can_place = false
			return
		
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			can_place = false
			return
		
		if grid_array[grid_to_check].state == grid_array[grid_to_check].States.TAKEN:
			can_place = false
			return
			
		can_place = true
		

func set_grids(slot: FactoryGridSlot):
	for grid_coord in item_held.item_grid:
		var xy = grid_coord.split(',')
		var grid_to_check = slot.slot_id + int(xy[0]) + int(xy[1]) * col_count
		var line_switch_check = slot.slot_id % col_count + int(xy[0])
			
		if line_switch_check < 0 or line_switch_check >= col_count:
			continue
			
			
		if grid_to_check < 0 or grid_to_check >= grid_array.size():
			continue
			
		
		if can_place:
			grid_array[grid_to_check].set_color(FactoryGridSlot.States.FREE)
			
			#Starting with item_anchor = Vector2(100000, 100000) (in _on_slot_mouse_entered)
			#First coord "1,1": 1 < 100000 → anchor becomes (1, 1)
			#Second coord "2,1": 2 < 1 is false, 1 < 1 is false → anchor stays (1, 1)
			#Third coord "1,2": 1 < 1 is false, 2 < 1 is false → anchor stays (1, 1)
			if int(xy[0]) < item_anchor.x: item_anchor.x = int(xy[0])
			if int(xy[1]) < item_anchor.y: item_anchor.y = int(xy[1])
			
		else:
			grid_array[grid_to_check].set_color(FactoryGridSlot.States.TAKEN)

func clear_grid():
	for slot: FactoryGridSlot in grid_array:
		slot.set_color(FactoryGridSlot.States.DEFAULT)

func place_item():
	if not can_place or not current_slot: 
		return #put indication of placement failed, sound or visual here
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	#for changing scene tree
	item_held.get_parent().remove_child(item_held)
	grid_container.add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	
	var calculated_grid_id = current_slot.slot_id + item_anchor.x + item_anchor.y * col_count 
	item_held._snap_to(grid_array[calculated_grid_id].global_position)
	
	item_held.grid_anchor = current_slot
	
	for grid_coord in item_held.item_grid:
		var xy = grid_coord.split(',')
		var grid_to_check = current_slot.slot_id + int(xy[0]) + int(xy[1]) * col_count
		
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN 
		grid_array[grid_to_check].item_stored = item_held
	
	#put item into a data storage here
	
	item_held = null
	clear_grid()

# PICK UP ITEM
func pick_item():
	if not current_slot or not current_slot.item_stored: 
		return
	item_held = current_slot.item_stored
	item_held.selected = true
	#move node in the scene tree
	item_held.get_parent().remove_child(item_held)
	add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	for grid_coord in item_held.item_grid:
		var xy = grid_coord.split(',')
		var grid_to_check = item_held.grid_anchor.slot_id + int(xy[0]) + int(xy[1]) * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE 
		grid_array[grid_to_check].item_stored = null
	
	item_held.picked_up()
	
	check_slot_availability(current_slot)
	set_grids.call_deferred(current_slot)

func _on_button_pressed(item_id: int) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	var new_item = item_scene.instantiate() as FactoryGridItem
	add_child(new_item)
	new_item.load_item(factory_type, item_id)    #randomize this for different items to spawn
	new_item.selected = true
	item_held = new_item
