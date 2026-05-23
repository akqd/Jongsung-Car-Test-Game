extends Node2D

# Scene references
const OBSTACLE_SCENE = preload("res://scenes/obstacle.tscn")

# Viewport dimensions
const VIEWPORT_WIDTH = 540
const VIEWPORT_HEIGHT = 960

# Drivable Lanes
const LANE_X = [145.0, 270.0, 395.0]

# Speed variables
var base_speed: float = 200.0
var max_speed: float = 400.0
var current_speed: float = 200.0
var target_distance: float = 1000.0

# Game progression variables
var distance_scroll: float = 0.0
var distance_traveled: float = 0.0 # in meters
var score: float = 0.0
var is_game_over: bool = false
var is_stage_cleared: bool = false

# Camera shake variables
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

# Level layout
var stage_data: Dictionary
var spawn_index: int = 0
var finish_line_spawned: bool = false
var finish_line_crossed: bool = false
var finish_line_y: float = -200.0

# Node references
@onready var road_node: Node2D = $Road
@onready var player_node: CharacterBody2D = $Player
@onready var camera_node: Camera2D = $Camera2D
@onready var hud_node: CanvasLayer = $HUD

func _ready() -> void:
	get_tree().paused = false # Unpause the game tree on start
	# 1. Load active stage settings
	var stage_num = Global.selected_stage
	stage_data = LevelData.get_stage_data(stage_num)
	
	base_speed = stage_data["base_speed"]
	max_speed = stage_data["max_speed"]
	current_speed = base_speed
	target_distance = stage_data["target_distance"]
	
	Global.current_score = 0
	
	# Apply road color if customizable
	if road_node and road_node.has_method("set_road_color"):
		road_node.set_road_color(stage_data["road_color"])

func _process(delta: float) -> void:
	if is_game_over or is_stage_cleared:
		# Slowly decelerate road on game over
		current_speed = lerp(current_speed, 0.0, 4.0 * delta)
		if road_node:
			road_node.scroll_road(current_speed, delta)
		
		# Animate finish line even during deceleration
		if finish_line_spawned and not finish_line_crossed:
			finish_line_y += current_speed * delta
		return
		
	# 1. Gradually accelerate as the player advances
	var progress = distance_traveled / target_distance
	current_speed = lerp(base_speed, max_speed, progress)
	
	# 2. Update distance and score
	distance_scroll += current_speed * delta
	distance_traveled = distance_scroll / 20.0 # Scale so speed feels realistic
	
	# Real-time base score (10 points per meter)
	score = (distance_traveled * 10.0) + (Global.current_score - (distance_traveled * 10.0) if Global.current_score > 0 else 0)
	Global.current_score = int(score)
	
	# 3. Scroll the road
	if road_node:
		road_node.scroll_road(current_speed, delta)
		
	# 4. Spawning obstacles based on deterministic layout
	check_spawns()
	
	# 5. Handle camera shake decay
	if shake_duration > 0:
		shake_duration -= delta
		camera_node.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if shake_duration <= 0:
			camera_node.offset = Vector2.ZERO
			
	# 6. Check for Finish Line Crossing
	if finish_line_spawned and not finish_line_crossed:
		finish_line_y += current_speed * delta
		if finish_line_y >= player_node.position.y - 30.0:
			# Player crossed finish line!
			trigger_stage_clear()

func check_spawns() -> void:
	# Read through sorted obstacles array
	var obstacles_list = stage_data["obstacles"]
	
	while spawn_index < obstacles_list.size() and distance_traveled >= obstacles_list[spawn_index]["dist"]:
		var spawn_info = obstacles_list[spawn_index]
		spawn_obstacle(spawn_info["lane"], spawn_info["type"])
		spawn_index += 1
		
	# Trigger Finish Line when target distance is reached
	if distance_traveled >= target_distance and not finish_line_spawned:
		spawn_finish_line()

func spawn_obstacle(lane_idx: int, type: String) -> void:
	# Correct 1-based lane index to 0-based
	var lane = clamp(lane_idx - 1, 0, 2)
	var x_pos = LANE_X[lane]
	
	var obs = OBSTACLE_SCENE.instantiate()
	obs.type = type
	obs.position = Vector2(x_pos, -80.0) # Start slightly offscreen top
	add_child(obs)

func spawn_finish_line() -> void:
	finish_line_spawned = true
	finish_line_y = -100.0 # Start offscreen top
	queue_redraw()

func shake_camera(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

func add_near_miss_bonus(obstacle_pos: Vector2) -> void:
	if is_game_over or is_stage_cleared:
		return
		
	# Award bonus score
	Global.current_score += 250
	
	# Show Floating Text popup
	if hud_node and hud_node.has_method("show_near_miss_popup"):
		hud_node.show_near_miss_popup(obstacle_pos)
		
	# Screen shake juice
	shake_camera(3.0, 0.2)

func on_player_died() -> void:
	if is_stage_cleared:
		return
	is_game_over = true
	
	# Save high score
	Global.update_high_score(Global.selected_stage, Global.current_score)
	
	# Show Game Over Panel in HUD
	if hud_node and hud_node.has_method("show_game_over"):
		hud_node.show_game_over()

func trigger_stage_clear() -> void:
	finish_line_crossed = true
	is_stage_cleared = true
	
	# Unlock next stage
	Global.unlock_next_stage()
	
	# Save high score
	Global.update_high_score(Global.selected_stage, Global.current_score)
	
	# Show Stage Clear Panel in HUD
	if hud_node and hud_node.has_method("show_stage_clear"):
		hud_node.show_stage_clear()

# Render the Checkered Finish Line if spawned
func _draw() -> void:
	if finish_line_spawned:
		# Draw a beautiful retro checkered banner across the road
		# Road boundaries: X=80 to X=460. Drivable range is 100 to 440, but checkered line covers the whole road
		var start_x = 80.0
		var end_x = 460.0
		var width = end_x - start_x
		var height = 48.0
		var box_size = 16.0
		
		# Draw asphalt base background
		draw_rect(Rect2(start_x, finish_line_y, width, height), Color("1a1a1a"), true)
		
		# Draw white checkered boxes
		var columns = int(width / box_size)
		var rows = int(height / box_size)
		for r in range(rows):
			for c in range(columns):
				if (r + c) % 2 == 0:
					draw_rect(
						Rect2(start_x + c * box_size, finish_line_y + r * box_size, box_size, box_size),
						Color("eceff4"), # Retro White
						true
					)
		
		# Draw golden border lines
		draw_line(Vector2(start_x, finish_line_y), Vector2(end_x, finish_line_y), Color("ebcb8b"), 3.0)
		draw_line(Vector2(start_x, finish_line_y + height), Vector2(end_x, finish_line_y + height), Color("ebcb8b"), 3.0)
