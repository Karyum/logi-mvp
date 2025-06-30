extends CanvasLayer
class_name HUD

@export var drawers_animation_speed = 0.4
#var build_drawer = false

signal on_building_factory(type: String)

var is_building_factory = false

@onready var time_label: Label = $TimeContainer/Time
@onready var truck_label: Label = $TruckContainer/Amount
@onready var inventory_ui: FactoryInventory = $FactoryInventory

func _ready():
	HudManager.set_hud(self)
	inventory_ui.visible = false
	EventBus.time_updated.connect(_on_time_update)
	
func open_factory_inventory(factory_data: Factory):
	if is_building_factory: return
	print('huh')
	inventory_ui.open_inventory(factory_data)
	EventBus.ui_factory_inventory_opened.emit(factory_data.position)
	_on_close_build_drawer_pressed()
	

func close_factory_inventory():
	inventory_ui.visible = false
	EventBus.ui_factory_inventory_closed.emit()

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
	is_building_factory = true
	update_label_status('Building Steel Factory')
	on_building_factory.emit('steel')


func _on_aluminium_factory_button_pressed() -> void:
	is_building_factory = true
	update_label_status('Building Aluminium Factory')
	on_building_factory.emit('aluminium')


func _on_bio_factory_button_pressed() -> void:
	is_building_factory = true
	update_label_status('Building Bio Factory')
	on_building_factory.emit('bio')
	

func update_label_status(text: String):
	$Status.text = text
