extends Label


@export var min_font_size := 8
@export var max_font_size := 64

func _ready():
	var label = self
	var available_size = label.size
	
	if label.text.is_empty() or available_size.x <= 0 or available_size.y <= 0:
		return
	
	# Get the font (use default if no theme override)
	var font = label.get_theme_font("font")
	if not font:
		font = ThemeDB.fallback_font
	
	var min_size = 1
	var max_size = 500
	var best_font_size = min_size
	
	# Binary search for the largest font size that fits
	while min_size <= max_size:
		var current_font_size = (min_size + max_size) / 2
		
		# Get actual text dimensions with this font size
		var text_size = font.get_multiline_string_size(
			label.text, 
			HORIZONTAL_ALIGNMENT_LEFT, 
			available_size.x,  # Max width (for word wrapping)
			current_font_size
		)
		
		# Check if it fits within the label bounds
		if text_size.x <= available_size.x and text_size.y <= available_size.y:
			best_font_size = current_font_size
			min_font_size = current_font_size + 1
		else:
			max_font_size = current_font_size - 1
	
	# Apply the calculated font size
	label.add_theme_font_size_override("font_size", best_font_size)
