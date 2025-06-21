extends Node

var hud: HUD = null

func set_hud(hud_instance: CanvasLayer):
	hud = hud_instance
	
func _call(method: String, args: Array):
	print("Forwarding method: %s with args: %s" % [method, args])
	
	# Check if hud exists and has the method
	if hud and hud.has_method(method):
		# Use callv to call the method with the arguments array
		return hud.callv(method, args)
	else:
		push_error("Method '%s' not found in hud" % method)
		return null
