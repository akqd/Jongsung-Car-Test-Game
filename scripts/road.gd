extends Node2D

# Road visual parameters
var road_color: Color = Color("2e3440") # Slate grey base
var grass_color: Color = Color("4f772d") # Dark green base
var road_offset: float = 0.0

func set_road_color(color: Color) -> void:
	road_color = color
	queue_redraw()

func scroll_road(speed: float, delta: float) -> void:
	# Add fmod to prevent float overflow and repeat perfectly
	road_offset = fmod(road_offset + speed * delta, 128.0)
	queue_redraw()

func _draw() -> void:
	# 1. Draw side grass shoulders (whole screen background first)
	draw_rect(Rect2(0, 0, 540, 960), grass_color, true)
	
	# 2. Draw asphalt highway body (center of screen)
	# Road width: 380 pixels (X = 80 to X = 460)
	draw_rect(Rect2(80, 0, 380, 960), road_color, true)
	
	# 3. Draw road shoulders/lines (yellow lines)
	draw_rect(Rect2(98, 0, 4, 960), Color("ebcb8b"), true)  # Left outer line
	draw_rect(Rect2(438, 0, 4, 960), Color("ebcb8b"), true) # Right outer line
	
	# 4. Draw safety side guardrails (red and white stripes on edges)
	var stripe_height = 32.0
	var guardrail_y = -128.0 + road_offset
	while guardrail_y < 960.0 + 128.0:
		var index = int((guardrail_y - road_offset) / stripe_height)
		var stripe_color = Color("bf616a") if index % 2 == 0 else Color("eceff4") # Red/White alternating
		
		# Left guardrail stripe
		draw_rect(Rect2(72, guardrail_y, 8, stripe_height), stripe_color, true)
		# Right guardrail stripe
		draw_rect(Rect2(460, guardrail_y, 8, stripe_height), stripe_color, true)
		
		guardrail_y += stripe_height
		
	# 5. Draw white dashed lane partition lines
	# Two partitions dividing 3 lanes:
	# Left partition X = 208, Right partition X = 328
	var dash_height = 64.0
	var dash_spacing = 128.0
	var current_y = -128.0 + road_offset
	
	while current_y < 960.0 + 128.0:
		# Draw dash for Left Lane separator
		draw_rect(Rect2(208, current_y, 4, dash_height), Color("eceff4"), true)
		# Draw dash for Right Lane separator
		draw_rect(Rect2(328, current_y, 4, dash_height), Color("eceff4"), true)
		
		current_y += dash_spacing
