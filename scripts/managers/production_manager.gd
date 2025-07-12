extends Node

var steel_factory_data = preload("res://scripts/resources/factories/steel.tres")
var aluminium_factory_data = preload("res://scripts/resources/factories/aluminium.tres")
var bio_factory_data = preload("res://scripts/resources/factories/bio.tres")
var oil_factory_data = preload("res://scripts/resources/factories/oil.tres")

var factory_scene = preload("res://scenes/factory/factory.tscn")

@onready var tree = get_tree()

var factories: Dictionary[Vector2i, Factory] = {}  # hex_pos -> Factory data
var selected_factory: Factory


func _ready() -> void:
	EventBus.factory_placed.connect(_on_player_placed_factory)
	EventBus.game_battle_turn.connect(_on_new_turn)
	#EventBus.ui_factory_inventory_opened.connect(_on_factory_inventory_opened)
	#EventBus.ui_factory_inventory_closed.connect(_on_factory_inventory_closed)

# Called when local player places a factory (initiates network sync)
func add_factory(player_id: int, hex_pos: Vector2i, factory_type: String):
	# Create the factory locally first
	if NetworkManager.is_host:
		_create_factory(player_id, hex_pos, factory_type)
		EventBus.factory_placed_rpc(player_id, hex_pos, factory_type)
	else:
		EventBus.factory_place_request_rpc_call.rpc(player_id, hex_pos, factory_type)
	
	

# Internal function that actually creates the factory (no network events)
func _create_factory(player_id: int, hex_pos: Vector2i, factory_type: String):
	var factory_data: Factory

	match factory_type:
		Factory.FactoryType.STEEL:
			factory_data = steel_factory_data.duplicate()
		Factory.FactoryType.ALUMINIUM:
			factory_data = aluminium_factory_data.duplicate()
		Factory.FactoryType.BIO:
			factory_data = bio_factory_data.duplicate()
		Factory.FactoryType.OIL:
			factory_data = oil_factory_data.duplicate()
	

	factory_data.position = hex_pos
	factory_data.player_id = player_id
	
	factories[hex_pos] = factory_data
	
	# Create visual representation
	var factory_node = factory_scene.instantiate() as FactoryScene
	var buildings_parent = tree.current_scene.get_node("Buildings")
	var global_hex_pos = MapManager.map.map_to_local(hex_pos)

	factory_node.position = global_hex_pos
	factory_node.factory_data = factory_data
	
	buildings_parent.add_child(factory_node)
		
func has_factory_at(hex_pos: Vector2i):
	if factories.has(hex_pos):
		return true
	
	return false
	
	
func save_factory_layout(factory_id: Vector2i, items: Array):
	if NetworkManager.is_host:
		factories[factory_id].items = items
		EventBus.factory_sync_items_rpc(factory_id, items)
	else:
		EventBus.factory_sync_items_request(factory_id, items)

func get_factory(factory_id: Vector2i) -> Factory:
	return factories[factory_id]


func find_factory_type_data(hex_pos: Vector2i) -> Factory:
	return factories[hex_pos]
	
func sync_factory_items(hex_pos: Vector2i, items: Array):
	factories[hex_pos].items = items
	
func sync_factories(new_factories: Dictionary[Vector2i, Factory]):
	
	factories = new_factories
	EventBus.factories_updated.emit()
	# emit signal to update UI just in case a player has the inventory opened

func _on_player_placed_factory(placing_player_id: int, hex_pos: Vector2i, factory_type: String):
	_create_factory(placing_player_id, hex_pos, factory_type)

func find_item_by_id(items: Array, target_id) -> Object:
	for item in items:
		if item.item_id == target_id:
			return item
	return null

func _on_new_turn(_new_turn: int):
	if not NetworkManager.is_host: return

	for factory_pos in factories.keys():
		var factory = factories[factory_pos] as Factory
		
		for item in factory.items:
			var factory_item_data = DataHandler.find_factory_item(factory.factory_type, item.item_id) as FactoryItem
			var item_in_storage = find_item_by_id(factory.factory_storage, item.item_id)
			
			if item_in_storage != null:
				item_in_storage.amount += factory_item_data.production_rate
			else:
				var new_item_storage = FactoryItemStorage.new()
				new_item_storage.item_id = item.item_id
				new_item_storage.amount = factory_item_data.production_rate
				factory.factory_storage.append(new_item_storage)
	
	EventBus.factories_sync_rpc(factories)
