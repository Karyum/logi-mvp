extends Node

var factory_items := {}
var factories := {}

@onready var factory_items_data = "res://data/factory_items.json"
@onready var factories_data = "res://data/factories.json"

func _ready() -> void:
	factory_items = load_data(factory_items_data)
	factories = load_data(factories_data)
	
func load_data(path) -> Dictionary:
	if not FileAccess.file_exists(path):
		printerr("File " + path + " was not found")
		
	var data_file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(data_file.get_as_text())
	
	data_file.close()
	
	return data

func fetch_factory_items(factory_type: String):
	return factory_items[factory_type]

func find_factory_item(factory_type: String, item_id: int):
	var factory_type_items = factory_items[factory_type] as Array
	
	for item in factory_type_items:
		if int(item['item_id']) == item_id:
			return item
	
func find_factory(factory_type: String):
	return factories[factory_type]
