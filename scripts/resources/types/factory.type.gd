extends Resource
class_name Factory

const FactoryType =  { 
	"STEEL": "steel",
	"ALUMINIUM": "aluminium",
	"BIO": "bio",
	"OIL": "oil"	
}

@export_enum("steel", "aluminium", "bio", "oil")
var factory_type: String

@export var grid_size: int
@export_file("*.png")  var factory_sprite
@export var position: Vector2i
@export var player_id: int
@export var items: Array
@export var factory_storage: Array[FactoryItemStorage]
