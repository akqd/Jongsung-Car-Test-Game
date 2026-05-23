extends Control

# Viewport speed in main menu for decorative background scroll
var current_speed: float = 80.0

@onready var road_node: Node2D = $Road

# Stage button references
@onready var stage1_btn: Button = $StagePanel/VBoxContainer/Stage1Button
@onready var stage2_btn: Button = $StagePanel/VBoxContainer/Stage2Button
@onready var stage3_btn: Button = $StagePanel/VBoxContainer/Stage3Button

func _ready() -> void:
	# Check unlock state and configure buttons
	stage1_btn.disabled = not Global.unlocked_stages[0]
	stage2_btn.disabled = not Global.unlocked_stages[1]
	stage3_btn.disabled = not Global.unlocked_stages[2]
	
	# Update text for locked states
	if stage2_btn.disabled:
		stage2_btn.text = "STAGE 2 [LOCKED]"
	else:
		stage2_btn.text = "STAGE 2: NORMAL"
		
	if stage3_btn.disabled:
		stage3_btn.text = "STAGE 3 [LOCKED]"
	else:
		stage3_btn.text = "STAGE 3: HARD"

func _process(delta: float) -> void:
	if road_node:
		road_node.scroll_road(current_speed, delta)

func _on_stage1_pressed() -> void:
	Global.selected_stage = 1
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_stage2_pressed() -> void:
	Global.selected_stage = 2
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_stage3_pressed() -> void:
	Global.selected_stage = 3
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
