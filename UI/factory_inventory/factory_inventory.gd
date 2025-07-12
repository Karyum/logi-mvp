extends Control
class_name FactoryInventory

@onready var slot_scene = preload("res://UI/factory_inventory/slot/slot.tscn")
@onready var item_scene = preload("res://UI/factory_inventory/item/factory_grid_item.tscn")
@onready var main_theme = preload('res://UI/themes/main.tres')
@onready var add_truck_button = preload('res://UI/small/add_truck/add_truck.tscn')
@onready var grid_container = $NinePatchRect/InventoryUI/Top/GridStorage/InventoryGrid
@onready var flow_container = $NinePatchRect/InventoryUI/Top/MarginContainer/DragButtons
@onready var col_count = grid_container.columns
@onready var storage = $NinePatchRect/InventoryUI/Top/GridStorage/StorageContainer/Storage
@onready var transports = $NinePatchRect/InventoryUI/Bottom/VBoxContainer/TransportContainer


@export var grid_size := 32
@export var factory_type := 'steel'

var grid_array : Array[FactoryGridSlot] = []
var item_held: FactoryGridItem
var current_slot: FactoryGridSlot = null
var item_anchor: Vector2
var can_place = false
var factory_id: Vector2i

var can_close_on_click = false

func _ready() -> void:
	EventBus.factories_updated.connect(_on_factroies_updated)


func create_items_list():
	for child in flow_container.get_children():
		flow_container.remove_child(child)
	var items = DataHandler.fetch_factory_items(factory_type)
	
	for item in items:
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_top", 5)
		margin.add_theme_constant_override("margin_bottom", 5)
		var new_button = Button.new()
		new_button.pressed.connect(func(): _on_button_pressed(item['item_id']))
		new_button.text = item['name']
		new_button.theme = main_theme
		new_button.add_theme_font_size_override("font_size", 24)

		margin.add_child(new_button)
		flow_container.add_child(margin)

func setup_add_trucks_buttons():
	for child in transports.get_children():
		child.queue_free()
		
	for i in range(3):
		var truck_button = add_truck_button.instantiate()
		transports.add_child(truck_button)
		truck_button.get_child(0).pressed.connect(func():
			_on_add_truck_click(i)
		)
		
func open_inventory(factory_data: Factory):
	factory_type = factory_data.factory_type.to_lower()
	grid_size = factory_data.grid_size
	visible = true
	
	factory_id = factory_data.position
	
	# Reset/clear existing grid
	clear_grid()  # Reset visual states
	
	# Remove existing slots from grid_container and clear the array
	for child in grid_container.get_children():
		child.queue_free()
	
	grid_array.clear()
	current_slot = null
	item_held = null
	EventBus.item_is_released.emit()
	
	for i in range(factory_data.grid_size):
		create_slot()
		
	create_items_list()
	setup_add_trucks_buttons()
	
	await get_tree().process_frame
	await get_tree().process_frame
	load_saved_items.call_deferred()
	load_saved_storage.call_deferred()
	
	# Enable closing after a short delay
	await get_tree().create_timer(0.1).timeout
	can_close_on_click = true

func has_clicked_within():
	return self.get_global_rect().has_point(get_viewport().get_mouse_position())


func hide_inventory():
	self.visible = false
	can_close_on_click = false
	
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and can_close_on_click:
		if not has_clicked_within():
			hide_inventory()

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

func _on_factroies_updated():
	if self.visible: 
		load_saved_items()
		load_saved_storage()

func save_current_layout():
	var items_to_save = []
	
	for slot in grid_array:
		if slot.item_stored and slot.state == slot.States.TAKEN:
			# Only save once per item (when we hit the anchor slot)
			if slot.item_stored.grid_anchor == slot:
				var min_x = 999999
				var min_y = 999999
				
				# Check all grid coordinates to find the top-left corner
				for grid_coord in slot.item_stored.item_grid:
					var actual_grid_id = slot.slot_id + grid_coord[0] + grid_coord[1] * col_count
					if actual_grid_id >= 0 and actual_grid_id < grid_array.size():
						var grid_x = actual_grid_id % col_count
						var grid_y = actual_grid_id / col_count
						
						if grid_x < min_x:
							min_x = grid_x
						if grid_y < min_y:
							min_y = grid_y
							
				var item_data = {
					"item_id": slot.item_stored.item_id,
					"grid_position": Vector2(min_x, min_y),
					"rotation": slot.item_stored.rotation_degrees,
					"item_grid": slot.item_stored.item_grid.duplicate()
				}

				items_to_save.append(item_data)

	ProductionManager.save_factory_layout(factory_id, items_to_save)

# This mainly runs when inventory opens 
func load_saved_items():
	
	var factory = ProductionManager.get_factory(factory_id)
	
	# Load the items on the grid
	for item_data in factory.items:
		var new_item = item_scene.instantiate() as FactoryGridItem
		grid_container.add_child(new_item)
		new_item.load_item(factory_type, item_data["item_id"])
		
		# Set rotation to match saved state
		if item_data["rotation"]: new_item.rotate_item()
		
		# Calculate grid position
		var grid_pos = item_data["grid_position"]
		var slot_id = int(grid_pos.x + grid_pos.y * col_count)
		
		if slot_id >= 0 and slot_id < grid_array.size():
			new_item._snap_to(grid_array[slot_id].global_position, 0)
			new_item.grid_anchor = grid_array[slot_id]
			
			# Mark grid slots as taken
			for grid_coord in item_data["item_grid"]:
				var grid_to_check = slot_id + grid_coord[0] + grid_coord[1] * col_count
				if grid_to_check >= 0 and grid_to_check < grid_array.size():
					grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN
					grid_array[grid_to_check].item_stored = new_item
					
	
func load_saved_storage():
	var factory = ProductionManager.get_factory(factory_id)
	
	for child in storage.get_children():
		child.queue_free()
	
	# Very hacky
	var static_storage_label = Label.new()
	static_storage_label.theme = main_theme
	static_storage_label.text = 'Storage items:'
	storage.add_child(static_storage_label)
	
	for storage_item: FactoryItemStorage in factory.factory_storage:
		var factory_item = DataHandler.find_factory_item(factory_type, storage_item.item_id)
		var label = Label.new()
		label.theme = main_theme
		label.text = factory_item.name + ': ' + str(storage_item.amount)
		
		storage.add_child(label)


func create_slot():
	var new_slot = slot_scene.instantiate() as FactoryGridSlot
	new_slot.slot_id = grid_array.size()
	grid_array.append(new_slot)
	grid_container.add_child(new_slot)
	
	new_slot.slot_entered.connect(_on_slot_mouse_entered)
	new_slot.slot_exited.connect(_on_slot_mouse_exited)
	
	
func _on_slot_mouse_entered(slot: FactoryGridSlot):
	if not is_instance_valid(slot):
		print("ERROR: Slot is already freed!")
		return
	
	current_slot = slot
	item_anchor = Vector2(100000, 100000)
	
	if item_held:
		clear_grid()
		check_slot_availability(current_slot)
		set_grids.call_deferred(current_slot)
	
func _on_slot_mouse_exited(_slot: FactoryGridSlot):
	pass
	#clear_grid()
	#
	#if not grid_container.get_global_rect().has_point(get_global_mouse_position()):
		#current_slot = null
	
func rotate_item():
	item_held.rotate_item()
	clear_grid()
	if current_slot:
		_on_slot_mouse_entered(current_slot)

func check_slot_availability(slot: FactoryGridSlot):
	for grid_coord in item_held.item_grid:
		var grid_to_check = slot.slot_id + grid_coord[0] + grid_coord[1] * col_count
		var line_switch_check = slot.slot_id % col_count + grid_coord[0]
		
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
		var grid_to_check = slot.slot_id + grid_coord[0] + grid_coord[1] * col_count
		var line_switch_check = slot.slot_id % col_count + grid_coord[0]
			
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
			if grid_coord[0] < item_anchor.x: item_anchor.x = grid_coord[0]
			if grid_coord[1] < item_anchor.y: item_anchor.y = grid_coord[1]
			
		else:
			grid_array[grid_to_check].set_color(FactoryGridSlot.States.TAKEN)

func clear_grid():
	for slot: FactoryGridSlot in grid_array:
		#if slot.state != slot.States.TAKEN:
		slot.set_color(FactoryGridSlot.States.DEFAULT)
	

func place_item():
	if not can_place or not current_slot: 
		print("FAILED: can_place=", can_place, " current_slot=", current_slot)
		return
	
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Move item to grid container
	item_held.get_parent().remove_child(item_held)
	grid_container.add_child(item_held)
	item_held.global_position = get_global_mouse_position()
	
	var calculated_grid_id = current_slot.slot_id + item_anchor.x + item_anchor.y * col_count 
	
	if calculated_grid_id < 0 or calculated_grid_id >= grid_array.size():
		print("ERROR: calculated_grid_id out of bounds!")
		return
	
	item_held._snap_to(grid_array[calculated_grid_id].global_position)
	item_held.grid_anchor = current_slot
	
	for grid_coord in item_held.item_grid:
		var grid_to_check = current_slot.slot_id + grid_coord[0] + grid_coord[1] * col_count
		
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.TAKEN 
		grid_array[grid_to_check].item_stored = item_held
	
	item_held = null
	EventBus.item_is_released.emit()
	clear_grid()
	
	save_current_layout()
	

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
	
	EventBus.item_is_held.emit()
	
	for grid_coord in item_held.item_grid:
		var grid_to_check = item_held.grid_anchor.slot_id + grid_coord[0] + grid_coord[1] * col_count
		grid_array[grid_to_check].state = grid_array[grid_to_check].States.FREE 
		grid_array[grid_to_check].item_stored = null
	
	item_held.picked_up()
	
	save_current_layout()
	
	check_slot_availability(current_slot)
	set_grids.call_deferred(current_slot)

func _on_button_pressed(item_id: int) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	var new_item = item_scene.instantiate() as FactoryGridItem
	add_child(new_item)
	new_item.load_item(factory_type, item_id)    #randomize this for different items to spawn
	new_item.selected = true
	item_held = new_item
	
	EventBus.item_is_held.emit()


func _on_close_button_pressed() -> void:
	hide_inventory()

func _on_add_truck_click(button_index: int):
	# TODO: Add truck to factory
	# 1. Check if there are trucks available to add
	# 2. Instantiate the truck manage scene and replace it with the button
	# 3. Make sure truck amount is deducted
	# 4. The data should be stored in TransportManager
	print(button_index)
