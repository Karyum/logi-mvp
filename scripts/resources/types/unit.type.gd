extends Resource
class_name ArmyUnit

const UnitType =  { 
	"INFANTRY": "INFANTRY", 
	"TANK": "TANK", 
	"ARTILLERY": "ARTILLERY"
 }


@export_enum("INFANTRY", "TANK", "ARTILLERY")
var unit_type: String
@export var attack_power: int = 1

@export var fuel_amount: int
@export var fuel_cons_rate: int

@export var food_amount: int
@export var food_cons_rate: int
