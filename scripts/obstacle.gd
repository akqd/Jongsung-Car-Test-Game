extends Area2D

# Obstacle properties
# Types: "rock", "broken_car", "wrong_way"
@export var type: String = "rock"
var speed_y: float = 0.0
var active_speed: float = 0.0 # Speed relative to the road

# Specific damage values
var damage_amount: float = 35.0

# Near-miss tracking
var player_inside_near_miss: bool = false
var near_miss_awarded: bool = false
var physical_hit_occurred: bool = false

# Flashing timers for Broken Car hazard lights
var hazard_timer: float = 0.0
var hazard_on: bool = false

# Warning timer for Wrong-way Drivers
var warning_time: float = 0.0
var is_warning_active: bool = true

func _ready() -> void:
	# Configure damage based on type
	match type:
		"rock":
			damage_amount = 35.0
		"broken_car":
			damage_amount = 50.0
		"wrong_way":
			damage_amount = 100.0 # Fatal or breaks shield immediately
			
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	
	# Connect near-miss signals
	var near_miss_node = get_node_or_null("NearMissArea")
	if near_miss_node:
		near_miss_node.body_entered.connect(_on_near_miss_entered)
		near_miss_node.body_exited.connect(_on_near_miss_exited)

func _process(delta: float) -> void:
	# 1. Update positions based on road scrolling speed from Game Manager
	var game_node = get_tree().current_scene
	var road_speed = 0.0
	if game_node and "current_speed" in game_node:
		road_speed = game_node.current_speed
		
	# Static obstacles move down at the speed of the road.
	# Moving obstacles (Wrong-way) move down even faster.
	if type == "wrong_way":
		# Moving down relative to road speed + their own engine speed
		active_speed = road_speed + 350.0
	else:
		active_speed = road_speed
		
	position.y += active_speed * delta
	
	# 2. Hazard lights animation for broken cars
	if type == "broken_car":
		hazard_timer += delta
		if hazard_timer >= 0.25: # Flash 4 times a second
			hazard_timer = 0.0
			hazard_on = not hazard_on
			queue_redraw()
			
	# 3. Flashing warning for wrong-way drivers when they are offscreen
	if type == "wrong_way" and position.y < 0.0:
		is_warning_active = true
		warning_time += delta
		if warning_time >= 0.15:
			warning_time = 0.0
			queue_redraw()
	else:
		if is_warning_active:
			is_warning_active = false
			queue_redraw()
			
	# 4. Out of bounds cleanup
	if position.y > 1050.0:
		# If it passed player completely without hit, double check near miss
		if player_inside_near_miss and not near_miss_awarded and not physical_hit_occurred:
			trigger_near_miss()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not physical_hit_occurred:
		physical_hit_occurred = true
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
		
		# Bullet-hell hit splash
		queue_free()

func _on_near_miss_entered(body: Node2D) -> void:
	if body.name == "Player" and not physical_hit_occurred:
		player_inside_near_miss = true

func _on_near_miss_exited(body: Node2D) -> void:
	if body.name == "Player" and player_inside_near_miss:
		player_inside_near_miss = false
		if not physical_hit_occurred and not near_miss_awarded:
			# Make sure player actually passed the obstacle (obstacle is below or near player level)
			if position.y > body.position.y - 40.0:
				trigger_near_miss()

func trigger_near_miss() -> void:
	near_miss_awarded = true
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("add_near_miss_bonus"):
		game_node.add_near_miss_bonus(position)

func _draw() -> void:
	# 1. Draw offscreen Warning Indicator for wrong-way drivers
	if type == "wrong_way" and position.y < 0.0:
		# Flash a glowing red warning arrow and outline at the top of the viewport
		var flash_step = int(Time.get_ticks_msec() / 150) % 2
		if flash_step == 0:
			var viewport_y = -position.y + 40.0 # Pin warning arrow at Y = 40 relative to obstacle origin
			
			# Red Warning Box
			draw_rect(Rect2(-24, viewport_y - 20, 48, 40), Color("bf616a"), false, 2.0)
			
			# Warning Exclamation mark
			draw_rect(Rect2(-3, viewport_y - 12, 6, 16), Color("bf616a"), true)
			draw_rect(Rect2(-3, viewport_y + 8, 6, 6), Color("bf616a"), true)
			
			# Warning arrow pointing down
			var pts = PackedVector2Array([
				Vector2(-12, viewport_y + 24),
				Vector2(12, viewport_y + 24),
				Vector2(0, viewport_y + 36)
			])
			draw_colored_polygon(pts, Color("bf616a"))
		return

	# 2. Draw Obstacle itself
	match type:
		"rock":
			# Draw a jagged, detailed 2D pixel-art rock
			var color_dark = Color("434c5e") # Dark grey
			var color_mid = Color("4c566a")  # Mid grey
			var color_light = Color("d8dee9")# Highlighting silver
			
			# Rock body (Octagon shape for jagged stone feel)
			var pts = PackedVector2Array([
				Vector2(-12, -18), Vector2(10, -18),
				Vector2(20, -8), Vector2(18, 12),
				Vector2(6, 20), Vector2(-12, 18),
				Vector2(-20, 8), Vector2(-18, -8)
			])
			draw_colored_polygon(pts, color_mid)
			
			# Jagged shadow/cracks
			draw_line(Vector2(-12, -18), Vector2(-6, 2), color_dark, 2.0)
			draw_line(Vector2(-6, 2), Vector2(6, 20), color_dark, 2.0)
			draw_line(Vector2(-18, -8), Vector2(20, -8), color_dark, 2.0)
			
			# Rock highlight (sun coming from top-left)
			draw_line(Vector2(-12, -18), Vector2(10, -18), color_light, 2.0)
			draw_line(Vector2(-18, -8), Vector2(-12, -18), color_light, 2.0)
			
		"broken_car":
			# Draw a gray hatchback car, with parts of it broken (smoke handles are in game.gd)
			# Tyres
			draw_rect(Rect2(-20, -25, 6, 12), Color("1a1a1a"), true)
			draw_rect(Rect2(14, -25, 6, 12), Color("1a1a1a"), true)
			draw_rect(Rect2(-20, 13, 6, 12), Color("1a1a1a"), true)
			draw_rect(Rect2(14, 13, 6, 12), Color("1a1a1a"), true)
			
			# Body
			draw_rect(Rect2(-16, -28, 32, 56), Color("4c566a"), true) # Base gray
			draw_rect(Rect2(-13, -24, 26, 48), Color("3b4252"), true) # Inner dark grey
			
			# Windows (Cracked glass)
			draw_rect(Rect2(-10, -10, 20, 24), Color("2e3440"), true) # cabin
			draw_rect(Rect2(-8, -7, 16, 16), Color("4c566a"), true) # dusty broken glass
			draw_line(Vector2(-6, -5), Vector2(6, 5), Color("d8dee9"), 1.0) # Crack 1
			draw_line(Vector2(4, -3), Vector2(-2, 7), Color("d8dee9"), 1.0) # Crack 2
			
			# Alternating Orange Hazard Flashing Lights
			var hazard_color = Color("d08770") if hazard_on else Color("4c566a")
			draw_circle(Vector2(-11, -26), 4, hazard_color) # Front Left hazard
			draw_circle(Vector2(11, 24), 4, hazard_color)  # Rear Right hazard
			
			var hazard_color_alt = Color("4c566a") if hazard_on else Color("d08770")
			draw_circle(Vector2(11, -26), 4, hazard_color_alt) # Front Right hazard
			draw_circle(Vector2(-11, 24), 4, hazard_color_alt) # Rear Left hazard
			
		"wrong_way":
			# Draw a Blue Wrong-Way Muscle Car charging down (headlights facing downwards)
			# Tyres
			draw_rect(Rect2(-20, -25, 6, 12), Color("1a1a1a"), true)
			draw_rect(Rect2(14, -25, 6, 12), Color("1a1a1a"), true)
			draw_rect(Rect2(-20, 13, 6, 12), Color("1a1a1a"), true)
			draw_rect(Rect2(14, 13, 6, 12), Color("1a1a1a"), true)
			
			# Muscle Car Body (Blue/Cyan styling)
			draw_rect(Rect2(-16, -28, 32, 56), Color("5e81ac"), true) # Royal Blue
			
			# White Racing Stripes
			draw_rect(Rect2(-8, -28, 3, 56), Color("eceff4"), true)
			draw_rect(Rect2(5, -28, 3, 56), Color("eceff4"), true)
			
			# Windshield (facing down, so cabin is placed lower)
			draw_rect(Rect2(-11, -12, 22, 22), Color("2e3440"), true)
			draw_rect(Rect2(-9, -9, 18, 15), Color("88c0d0"), true) # Cyan Glass
			
			# Glowing Headlights on the BOTTOM side (facing downwards)
			draw_circle(Vector2(-10, 26), 4.5, Color("ebcb8b")) # Yellow left headlight
			draw_circle(Vector2(10, 26), 4.5, Color("ebcb8b"))  # Yellow right headlight
			
			# Taillights on the TOP side
			draw_rect(Rect2(-12, -28, 5, 2), Color("bf616a"), true)
			draw_rect(Rect2(7, -28, 5, 2), Color("bf616a"), true)
