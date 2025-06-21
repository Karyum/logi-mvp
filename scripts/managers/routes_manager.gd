extends Node

var total_trucks: int = 0
var available_trucks: int = 0

# future
var total_cargo_planes: int = 0
var available_cargo_planes: int = 0

var ongoing_routes: Dictionary = {}

func setup_transport(trucks_amount: int):
	total_trucks = trucks_amount
	available_trucks = trucks_amount
	HudManager.hud.update_truck_amount(trucks_amount)
	
	
	
	
## NETWORK
#@rpc("authority", "call_remote", "reliable")
#func sync_transport_rpc(trucks_amount: int):
	#total_trucks = trucks_amount
	#available_trucks = trucks_amount
	#HudManager.hud.update_truck_amount(trucks_amount)
