extends Node

var total_trucks: int = 0
var available_trucks: int = 0
var players_trucks: Dictionary[int, Dictionary] = {}

# future
var total_cargo_planes: int = 0
var available_cargo_planes: int = 0

var ongoing_routes: Dictionary = {}
var transports: Dictionary[int, TransportUnit]

func setup_transport(trucks_amount: int):
	total_trucks = trucks_amount
	available_trucks = trucks_amount
	HudManager.hud.update_truck_amount(trucks_amount)
	
	# Setup the state data for trucks and transport
	if not NetworkManager.is_host: return
	
	for player_id in GameState.players.keys():
		players_trucks[player_id] = {
			'available_trucks': total_trucks,
			'total_trucks': total_trucks
		}
	
	EventBus.transport_sync_trucks.rpc(var_to_str(players_trucks))
	
func sync_trucks(new_trucks: Dictionary):
	players_trucks = new_trucks
	
