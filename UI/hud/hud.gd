extends CanvasLayer

@export var drawers_animation_speed = 0.4
var build_drawer = false

signal on_building_factory(type: String)


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
