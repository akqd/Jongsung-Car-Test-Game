extends Node

# Global game state and save system
var current_score: int = 0
var high_scores: Array = [0, 0, 0] # Stage 1, 2, 3
var selected_stage: int = 1
var unlocked_stages: Array = [true, false, false] # Stage 1 unlocked by default

const SAVE_PATH = "user://jongsung_save.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_inputs()
	load_game()

# Setup input maps programmatically to ensure robust desktop & mobile execution
func setup_inputs() -> void:
	# Add move_left
	if not InputMap.has_action("move_left"):
		InputMap.add_action("move_left")
		# Left Arrow
		var ev_left = InputEventKey.new()
		ev_left.physical_keycode = KEY_LEFT
		InputMap.action_add_event("move_left", ev_left)
		# A key
		var ev_a = InputEventKey.new()
		ev_a.physical_keycode = KEY_A
		InputMap.action_add_event("move_left", ev_a)
	
	# Add move_right
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		# Right Arrow
		var ev_right = InputEventKey.new()
		ev_right.physical_keycode = KEY_RIGHT
		InputMap.action_add_event("move_right", ev_right)
		# D key
		var ev_d = InputEventKey.new()
		ev_d.physical_keycode = KEY_D
		InputMap.action_add_event("move_right", ev_d)

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("progression", "unlocked_stages", unlocked_stages)
	config.set_value("scores", "high_scores", high_scores)
	config.save(SAVE_PATH)

func load_game() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		unlocked_stages = config.get_value("progression", "unlocked_stages", unlocked_stages)
		high_scores = config.get_value("scores", "high_scores", high_scores)

func unlock_next_stage() -> void:
	if selected_stage < 3:
		unlocked_stages[selected_stage] = true # Selected stage is 1-indexed, so selected_stage corresponds to index of stage + 1 (e.g. stage 1 unlocks index 1, i.e., stage 2)
		save_game()

func update_high_score(stage: int, score: int) -> bool:
	var idx = stage - 1
	if idx >= 0 and idx < high_scores.size():
		if score > high_scores[idx]:
			high_scores[idx] = score
			save_game()
			return true
	return false
