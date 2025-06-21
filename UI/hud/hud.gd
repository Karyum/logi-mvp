extends CanvasLayer
class_name HUD

@export var drawers_animation_speed = 0.4
var build_drawer = false

signal on_building_factory(type: String)

@onready var time_label: Label = $TimeContainer/Time
@onready var truck_label: Label = $TruckContainer/Amount

func _ready():
	HudManager.set_hud(self)
	GameState.game_time_updated.connect(_on_time_update)

func _on_build_button_pressed() -> void:
	print('Open building drawer')
	toggle_building_drawer(true)
	

func _on_close_build_drawer_pressed() -> void:
	toggle_building_drawer(false)

func toggle_building_drawer(show_drawer: bool):
	var tween = get_tree().create_tween()
	var width = $BuildingDrawer.size.x
	
	if show_drawer:
		tween.tween_property($BuildingDrawer,"position", Vector2(0, 0), drawers_animation_speed)
	else:
		tween.tween_property($BuildingDrawer, "position", Vector2(-width, 0), drawers_animation_speed)


func _on_time_update(new_time: float):
	var total_seconds = int(new_time)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	
	var time_string = "%02d:%02d:%02d" % [hours, minutes, seconds]
	
	time_label.text = time_string

func update_truck_amount(amount: int):
	truck_label.text = str(amount) + 'x'

func _on_steel_factory_button_pressed() -> void:
	update_label_status('Building Steel Factory')
	on_building_factory.emit('steel')


func _on_aluminium_factory_button_pressed() -> void:
	update_label_status('Building Aluminium Factory')
	on_building_factory.emit('aluminium')


func _on_bio_factory_button_pressed() -> void:
	update_label_status('Building Bio Factory')
	on_building_factory.emit('bio')
	

func update_label_status(text: String):
	$Status.text = text
