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
