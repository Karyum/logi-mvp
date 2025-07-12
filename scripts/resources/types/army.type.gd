extends Resource
class_name Army

var player_id: int = 0
var current_pos: Vector2i = Vector2i.ZERO
var unit_id: String = ''
var units: Array[ArmyUnit] = []
var total_fuel_amount: int
var total_fuel_cons_rate: int

var total_food_amount: int
var total_food_cons_rate: int
