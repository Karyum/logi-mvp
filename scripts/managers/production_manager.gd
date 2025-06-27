extends Node

var steel_factory_data = preload("res://scripts/resources/factories/steel.tres")
var aluminium_factory_data = preload("res://scripts/resources/factories/aluminium.tres")
var bio_factory_data = preload("res://scripts/resources/factories/bio.tres")
var oil_factory_data = preload("res://scripts/resources/factories/oil.tres")

var factory_scene = preload("res://scenes/factory/factory.tscn")

@onready var tree = get_tree()

var factories: Dictionary[Vector2i, Factory] = {}  # hex_pos -> Factory data


func _ready() -> void:
	EventBus.factory_placed.connect(_on_player_placed_factory)

# Called when local player places a factory (initiates network sync)
func add_factory(player_id: int, hex_pos: Vector2i, factory_type: String):
	# Create the factory locally first
	_create_factory(player_id, hex_pos, factory_type)
	
	# Then notify other players via network
	EventBus.factory_placed.emit(player_id, hex_pos, factory_type)
	EventBus.factory_placed_rpc(player_id, hex_pos, factory_type)

# Internal function that actually creates the factory (no network events)
func _create_factory(player_id: int, hex_pos: Vector2i, factory_type: String):
	# Prevent duplicate factories at the same position
	if factories.has(hex_pos):
		print("Factory already exists at position: ", hex_pos)
		return
	
	var factory_data: Factory

	match factory_type.to_upper():
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

func find_factory_type_data(hex_pos: Vector2i) -> Factory:
	return factories[hex_pos]

func _on_player_placed_factory(placing_player_id: int, hex_pos: Vector2i, factory_type: String):
	if NetworkManager.player_id != placing_player_id:
		print(NetworkManager.player_id, placing_player_id)
		_create_factory(placing_player_id, hex_pos, factory_type)
	# we need also player_id 
	# Add the key of hex_pos to this new factory
	# get some of it's data from the resource
	# we might also want to have the items data of the factory in that resource
	# then sync with other players
	
	#factories[hex_pos] = factory_data
	#
	## Update player factory count
	#var owner_id = factory_data.get("owner_id", 0)
	#if GameState.players.has(owner_id):
		#GameState.players[owner_id].factories_count += 1
	
	#sync_production_rpc.rpc(factories)
	#
#@rpc("any_peer", "call_local", "reliable")
#func sync_production_rpc(updated_factories: Dictionary):
	#factories = updated_factories
	#GameState.notify_state_updated()
