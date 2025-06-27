extends Panel
class_name  FactoryGridSlot

signal slot_entered(slot)
signal slot_exited(slot)

@onready var filter = $MarginContainer/StatusFilter

var slot_id
var is_hovering := false
enum States {DEFAULT, TAKEN, FREE}
var state := States.DEFAULT
var item_stored = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_over = get_global_rect().has_point(get_global_mouse_position())
	
	if mouse_over and not is_hovering:
		is_hovering = true
		slot_entered.emit(self)
	elif not mouse_over and is_hovering:
		is_hovering = false
		slot_exited.emit(self)

func set_color(new_state = States.DEFAULT) -> void:
	match new_state:
		States.DEFAULT:
			filter.color = Color(Color.WHITE, 0.0)
		States.TAKEN:
			filter.color = Color(Color.WHITE, 0.0)
		States.FREE:
			filter.color = Color(Color.DARK_GRAY, 1.0)
