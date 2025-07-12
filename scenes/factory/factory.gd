extends Node2D
class_name FactoryScene

var factory_data: Factory
#TODO fix me
func _ready() -> void:
	var tex = load(factory_data.factory_sprite)
	$Sprite2D.texture = tex

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var sprite = $Sprite2D
		var sprite_rect = Rect2(sprite.global_position - (sprite.texture.get_size() * sprite.scale * 0.5), sprite.texture.get_size() * sprite.scale)
		
		if sprite_rect.has_point(get_global_mouse_position()):
			# Check if inventory is open
			if HudManager.hud.inventory_ui.visible:
				if HudManager.hud.inventory_ui.has_clicked_within():
					# Sprite is under the inventory - ignore the click
					return
			
			# Hide inventory before opening just in case one is already open
			HudManager.hud.inventory_ui.hide_inventory()
			HudManager.hud.open_factory_inventory(factory_data)
