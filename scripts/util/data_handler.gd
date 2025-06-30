extends Node



var factory_items := {}

@onready var factory_items_data = "res://data/factory_items.json"

func _ready() -> void:
	#factory_items = load_data(factory_items_data)
	load_items()
	
func load_data(path) -> Dictionary:
	if not FileAccess.file_exists(path):
		printerr("File " + path + " was not found")
		
	var data_file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(data_file.get_as_text())
	
	data_file.close()
	
	return data
	
func load_items():
	var items_path = "res://scripts/resources/factories_items/"
	var directories = DirAccess.get_directories_at(items_path)
	
	for directory in directories:
		factory_items[directory] = []
		var items = DirAccess.get_files_at(items_path + directory)
		for item in items:
			if not is_resource_file(item):
				continue

			var loaded_item = load(items_path + directory + '/' + item) as FactoryItem
			factory_items[directory].append(loaded_item)
		
		

func fetch_factory_items(factory_type: String):
	return factory_items[factory_type]

func find_factory_item(factory_type: String, item_id: int):
	var factory_type_items = factory_items[factory_type] as Array
	
	for item in factory_type_items:
		if int(item['item_id']) == item_id:
			return item
	
static func is_resource_file(filename: String) -> bool:
	# .tres - found during development/testing
	# .resc - found in exported game
	# .res - manual binary resources (less common)
	return filename.ends_with(".tres") or filename.ends_with(".res") or filename.ends_with(".resc")
