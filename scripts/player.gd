extends CharacterBody2D

signal shield_changed(current_shield, max_shield)
signal hit_taken
signal player_died

# Movement variables
@export var speed_x: float = 400.0
@export var acceleration: float = 12.0
@export var deceleration: float = 10.0

# Road bounds (Screen width 540)
const ROAD_LEFT = 110.0
const ROAD_RIGHT = 430.0

# Shield & Life variables
@export var max_shield: float = 100.0
var current_shield: float = 100.0
var is_invincible: bool = false
var is_dead: bool = false

# Timers
@onready var recharge_timer: Timer = get_node_or_null("RechargeTimer")
@onready var invincibility_timer: Timer = get_node_or_null("InvincibilityTimer")

# Shield properties
var shield_recharge_rate: float = 15.0 # per second
var is_recharging: bool = false

# Blinking effect for invincibility
var blink_time: float = 0.0
var blink_visible: bool = true

func _ready() -> void:
	# Position at bottom center of screen initially
	position = Vector2(270.0, 800.0)
	current_shield = max_shield
	emit_signal("shield_changed", current_shield, max_shield)
	
	# Configure timers
	if recharge_timer:
		recharge_timer.one_shot = true
		recharge_timer.wait_time = 3.0
		recharge_timer.timeout.connect(_on_recharge_timer_timeout)
	
	if invincibility_timer:
		invincibility_timer.one_shot = true
		invincibility_timer.wait_time = 1.5
		invincibility_timer.timeout.connect(_on_invincibility_timer_timeout)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# 1. Handling horizontal movement with inertia
	var input_dir = 0.0
	if Input.is_action_pressed("move_left"):
		input_dir -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir += 1.0
		
	# Touch screen controls for mobile
	if input_dir == 0.0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var touch_pos = get_viewport().get_mouse_position()
		if touch_pos.x < 270:
			input_dir = -1.0
		else:
			input_dir = 1.0
			
	# Apply velocity
	if input_dir != 0.0:
		velocity.x = lerp(velocity.x, input_dir * speed_x, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration * delta)
		
	# Move the character
	move_and_slide()
	
	# Clamp positions to road boundaries
	position.x = clamp(position.x, ROAD_LEFT, ROAD_RIGHT)
	
	# 2. Shield Regeneration
	if is_recharging and current_shield < max_shield:
		current_shield = min(current_shield + shield_recharge_rate * delta, max_shield)
		emit_signal("shield_changed", current_shield, max_shield)
		
	# 3. Invincibility Blinking
	if is_invincible:
		blink_time += delta
		if blink_time >= 0.1:
			blink_time = 0.0
			blink_visible = not blink_visible
			queue_redraw()
	else:
		if not blink_visible:
			blink_visible = true
			queue_redraw()

func take_damage(amount: float) -> void:
	if is_invincible or is_dead:
		return
		
	is_invincible = true
	is_recharging = false
	if invincibility_timer:
		invincibility_timer.start()
	if recharge_timer:
		recharge_timer.start() # Restart 3 sec delay before recharging
	
	# Spawn impact sparks using CPUParticles2D if available
	var particle = get_node_or_null("SparkParticles")
	if particle:
		particle.emitting = true
		
	if current_shield > 0:
		current_shield = max(current_shield - amount, 0.0)
		emit_signal("shield_changed", current_shield, max_shield)
		emit_signal("hit_taken")
		
		# Screen shake trigger via Game Manager
		var game_node = get_tree().current_scene
		if game_node and game_node.has_method("shake_camera"):
			game_node.shake_camera(6.0, 0.4)
	else:
		# Shield already 0, player dies!
		die()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	emit_signal("player_died")
	queue_redraw()
	
	# Death particles
	var death_particle = get_node_or_null("DeathParticles")
	if death_particle:
		death_particle.emitting = true
		
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("shake_camera"):
		game_node.shake_camera(15.0, 0.8)
		if game_node.has_method("on_player_died"):
			game_node.on_player_died()

func _on_recharge_timer_timeout() -> void:
	is_recharging = true

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false
	blink_visible = true
	queue_redraw()

# Procedural retro drawing of the player car
func _draw() -> void:
	if is_dead:
		# Draw burnt chassis
		draw_rect(Rect2(-15, -30, 30, 60), Color("3b4252"), true)
		return
		
	if not blink_visible:
		return
		
	# Draw tyres
	draw_rect(Rect2(-18, -25, 6, 12), Color("1a1a1a"), true) # Top-Left
	draw_rect(Rect2(12, -25, 6, 12), Color("1a1a1a"), true)  # Top-Right
	draw_rect(Rect2(-18, 13, 6, 12), Color("1a1a1a"), true)  # Bottom-Left
	draw_rect(Rect2(12, 13, 6, 12), Color("1a1a1a"), true)   # Bottom-Right
	
	# Draw main car body (Red Sports Car)
	var body_color = Color("bf616a") # Retro Red
	draw_rect(Rect2(-14, -28, 28, 56), body_color, true)
	
	# Car roof & hood details
	draw_rect(Rect2(-10, -10, 20, 24), Color("2e3440"), true) # Cabin area
	draw_rect(Rect2(-8, -7, 16, 16), Color("88c0d0"), true) # Windshield (Ice Blue)
	
	# Spoiler
	draw_rect(Rect2(-16, 24, 32, 6), Color("5e81ac"), true) # Blue spoiler wing
	
	# Headlights
	draw_circle(Vector2(-9, -26), 3, Color("ebcb8b")) # Yellow left headlight
	draw_circle(Vector2(9, -26), 3, Color("ebcb8b"))  # Yellow right headlight
	
	# Taillights
	draw_rect(Rect2(-12, 26, 5, 2), Color("bf616a"), true) # Red left brake light
	draw_rect(Rect2(7, 26, 5, 2), Color("bf616a"), true)  # Red right brake light
	
	# Draw Shield bubble if active
	if current_shield > 0:
		var shield_ratio = current_shield / max_shield
		var shield_color = Color(0.5, 0.8, 1.0, 0.15 * shield_ratio + 0.05)
		var outline_color = Color(0.5, 0.9, 1.0, 0.6 * shield_ratio + 0.1)
		
		# Pulsing effect based on time
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 2.0
		draw_circle(Vector2.ZERO, 38.0 + pulse, shield_color)
		draw_arc(Vector2.ZERO, 38.0 + pulse, 0.0, TAU, 32, outline_color, 2.0)
