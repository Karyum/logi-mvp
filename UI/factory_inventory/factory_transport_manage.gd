extends Control

var is_holding_item = false
var truck_id = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.item_is_held.connect(_on_item_held)
	EventBus.item_is_released.connect(_on_item_released)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse_leftclick") and has_clicked_within() and is_holding_item:
		EventBus.item_added_to_trucl.emit()
		

func setup(new_truck_id: int):
	truck_id = new_truck_id

func has_clicked_within():
	return self.get_global_rect().has_point(get_viewport().get_mouse_position())

func _on_item_held():
	is_holding_item = true

func _on_item_released():
	is_holding_item = false
