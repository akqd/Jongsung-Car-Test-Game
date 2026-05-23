extends CanvasLayer

# Node references (configured dynamically in _ready or mapped directly)
@onready var score_label: Label = $HUDContainer/TopBar/ScoreContainer/ScoreLabel
@onready var speed_label: Label = $HUDContainer/TopBar/SpeedContainer/SpeedLabel
@onready var shield_bar: ProgressBar = $HUDContainer/BottomBar/ShieldContainer/ShieldBar
@onready var progress_bar: ProgressBar = $HUDContainer/BottomBar/ProgressContainer/ProgressBar

@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_score: Label = $GameOverPanel/VBoxContainer/ScoreLabel

@onready var stage_clear_panel: Panel = $StageClearPanel
@onready var stage_clear_score: Label = $StageClearPanel/VBoxContainer/ScoreLabel
@onready var next_stage_button: Button = $StageClearPanel/VBoxContainer/HBoxContainer/NextButton

var game_node: Node2D = null

func _ready() -> void:
	game_node = get_tree().current_scene
	
	# Connect signals from player if player exists
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Search by path if group is not set up
		player = game_node.get_node_or_null("Player")
		
	if player:
		player.shield_changed.connect(_on_player_shield_changed)
		
	# Hide overlays initially
	game_over_panel.visible = false
	stage_clear_panel.visible = false
	
	# Pause mode safety
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	stage_clear_panel.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not game_node:
		return
		
	# 1. Update score
	score_label.text = "SCORE: %06d" % Global.current_score
	
	# 2. Update speedometer
	# KM/H is proportional to player speed
	if "current_speed" in game_node:
		var display_speed = int(game_node.current_speed * 0.6)
		speed_label.text = "%d KM/H" % display_speed
	
	# 3. Update level progress
	if "target_distance" in game_node and "distance_traveled" in game_node:
		if game_node.target_distance > 0:
			var progress = clamp(game_node.distance_traveled / game_node.target_distance, 0.0, 1.0)
			progress_bar.value = progress * 100.0

func _on_player_shield_changed(current_shield: float, max_shield: float) -> void:
	shield_bar.value = current_shield
	
	# Safe duplication of stylebox to prevent read-only modifier crashes
	var sb = shield_bar.get_theme_stylebox("fill")
	if sb:
		var dup_sb = sb.duplicate()
		if dup_sb is StyleBoxFlat:
			if current_shield <= 30.0:
				dup_sb.bg_color = Color("bf616a") # Retro Red warning
			else:
				dup_sb.bg_color = Color("88c0d0") # Ice neon blue
			shield_bar.add_theme_stylebox_override("fill", dup_sb)

func show_near_miss_popup(world_pos: Vector2) -> void:
	# Convert world coordinate to viewport canvas coordinate
	var canvas_pos = world_pos
	
	# Create floating label
	var label = Label.new()
	label.text = "+250 NEAR MISS!"
	label.position = canvas_pos - Vector2(70, 30) # Offset center
	
	# Style the text beautifully with bright orange retro color
	label.add_theme_color_override("font_color", Color("d08770")) # Vivid orange
	label.add_theme_color_override("font_outline_color", Color("2e3440")) # Dark outline
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 16)
	
	add_child(label)
	
	# Smooth floating juice animation using Godot 4 Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:x", label.position.x + randf_range(-15.0, 15.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Free memory when complete
	tween.chain().tween_callback(label.queue_free)

func show_game_over() -> void:
	get_tree().paused = true
	game_over_score.text = "FINAL SCORE: %06d" % Global.current_score
	game_over_panel.visible = true

func show_stage_clear() -> void:
	get_tree().paused = true
	stage_clear_score.text = "FINAL SCORE: %06d" % Global.current_score
	stage_clear_panel.visible = true
	
	# Disable next stage button if we just beat stage 3
	if Global.selected_stage >= 3:
		next_stage_button.visible = false

# UI Button Signals
func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_next_pressed() -> void:
	get_tree().paused = false
	Global.selected_stage += 1
	get_tree().reload_current_scene()
