extends Resource
class_name Factory

const FactoryType =  { 
	"STEEL": "STEEL",
	"ALUMINIUM": "ALUMINIUM",
	"BIO": "BIO",
	"OIL": "OIL"	
}

@export_enum("STEEL", "ALUMINIUM", "BIO", "OIL")
var factory_type: String

@export var grid_size: int
@export_file("*.png")  var factory_sprite
@export var position: Vector2i
@export var player_id: int
@export var items: Array
