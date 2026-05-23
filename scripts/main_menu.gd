extends Control

# Viewport speed in main menu for decorative background scroll
var current_speed: float = 120.0

@onready var road_node: Node2D = $Road
@onready var menu_panel: VBoxContainer = $MenuPanel
@onready var records_panel: Panel = $RecordsPanel

# High score label references
@onready var s1_score: Label = $RecordsPanel/VBoxContainer/ScoreGrid/S1Score
@onready var s2_score: Label = $RecordsPanel/VBoxContainer/ScoreGrid/S2Score
@onready var s3_score: Label = $RecordsPanel/VBoxContainer/ScoreGrid/S3Score

func _ready() -> void:
	records_panel.visible = false
	menu_panel.visible = true

func _process(delta: float) -> void:
	if road_node:
		road_node.scroll_road(current_speed, delta)

func _on_start_pressed() -> void:
	# Navigate to Stage Select Screen
	get_tree().change_scene_to_file("res://scenes/stage_select.tscn")

func _on_records_pressed() -> void:
	# Update high score values from Global
	s1_score.text = "%06d" % Global.high_scores[0]
	s2_score.text = "%06d" % Global.high_scores[1]
	s3_score.text = "%06d" % Global.high_scores[2]
	
	menu_panel.visible = false
	records_panel.visible = true

func _on_records_back_pressed() -> void:
	records_panel.visible = false
	menu_panel.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()
