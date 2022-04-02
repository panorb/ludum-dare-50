extends Node

signal tick_interval_update(tick_interval)
signal dialogue_play(identifier, lines)
signal countdown_start(identifier)
signal pause_mode_change(state)
signal manual_mode_change(state)
signal level_change(level)
signal exit_ready

var current_level : String = "empty"

func _ready():
	yield(get_tree(), "idle_frame")
	play_dialogue("tutorial-empty-1", [
		"...",
		"...........",
		"Okay. Let's get this over with... *sigh*",
		"Hello human. This is the training for AI 87416 you signed up for.",
		"You will provide part of a dataset that will be used to train a self steering robot.",
		"To control the robot you will use the terminal before you.",
		"...",
		"Let's start simple. Please enter one of the directions: [left, right, up, down] and press enter."
	])

# Gets called every tick
func handle_tick(level_stats: Dictionary):
	var objective_achieved = level_objective_achieved(level_stats)
	var level_name = current_level
	
	if level_name == "empty":
		if level_stats["level_ticks"] == 1:
			play_dialogue("tutorial-empty-2", ["Okay. Again. Enter [left, right, up, down] and press enter."])
		if level_stats["level_ticks"] == 2:
			play_dialogue("tutorial-empty-3", ["...",
											"Once more... a direction you haven't tried yet. [left, right, up, down] and then enter."])
		if level_stats["level_ticks"] == 3:
			play_dialogue("tutorial-empty-4", ["Alright.",
												"From now on the robot will move forward automatically...",
												"At a variable interval we will call 'tick' from now on.",
												"Let's start with 1 tick per second. Steer for a bit.",
												"[left, right, up, down] and then enter to change direction"])
		if level_stats["level_ticks"] == 14:
			play_dialogue("tutorial-empty-5", ["Hope you got that. Lets go a bit faster now.",
												"Get over to that '[color=#5d7643]>[/color]' tile I opened for you."])
			update_tick_interval(0.8)
			
	if objective_achieved:
		emit_signal("exit_ready")

# Gets called when player enters exit tile
func handle_exit():
	var level_name = current_level
	pause_game()
	
	if level_name == "empty":
		change_level("wall_explanation")
		play_dialogue("tutorial-wall", ["Alright... Walls. Don't crash into them. *shrug*",
										"Let's practice that for a bit by moving close to a wall.",
										"Hug the wall for a bit... Without crashing."])
	if level_name == "wall_explanation":
		change_level("timer_explanation")
		play_dialogue("tutorial-timer", ["So *these* blocks... They count down every tick...",
										"When they reach 0 they act like a wall for one tick.",
										"Move over a few of these tiles without crashing."])
	if level_name == "timer_explanation":
		change_level("only_once_explanation")
		play_dialogue("tutorial-only-once", ["This is taking too long. Let's speed up the ticks a bit.",
											"... Done... Okay, where were we?...",
											"These pipes are unstable. See for yourself."])
		update_tick_interval(0.6)
		
	if level_name == "only_once_explanation":
		change_level("wrap_around_explanation")
		play_dialogue("tutorial-wrap-around", ["Maybe you noticed by now. Maybe you didn't.",
												"You'll figure it out... Probably."])
	if level_name == "wrap_around_explanation":
		change_level("empty") # TODO: change this, go into main game loop


# Checks if the objective for the current level are achieved
func level_objective_achieved(level_stats: Dictionary) -> bool:
	var level_name = current_level
	
	if level_name == "empty":
		return level_stats["level_ticks"] >= 14
	if level_name == "wall_explanation":
		return level_stats["close_to_wall_ticks"] >= 3
	if level_name == "timer_explanation":
		return level_stats["passed_timer_fields"] >= 3
	if level_name == "only_once_explanation":
		return level_stats["passed_only_once_fields"] >= 8
	if level_name == "wrap_around_explanation":
		return true

	return false

func update_tick_interval(tick_interval : float) -> void:
	emit_signal("tick_interval_update", tick_interval)

func pause_game() -> void:
	emit_signal("pause_mode_change", true)

func unpause_game() -> void:
	emit_signal("pause_mode_change", false)

func start_countdown(identifier := ""):
	emit_signal("countdown_start", identifier)

func play_dialogue(identifier: String, lines: Array):
	# TODO: Implement dialogue systems
	pause_game()
	emit_signal("dialogue_play", [identifier, lines])
	
	# print("Skipped dialogue " + identifier + ". Not implemented.")
	# _on_Dialogue_finished(identifier)

func change_level(level_name: String):
	emit_signal("level_change", level_name)
	current_level = level_name

func _on_Countdown_finished(identifier : String):
	unpause_game()

func _on_Dialogue_finished(identifier : String):
	print(identifier)
	
	if identifier == "tutorial-empty-4":
		pause_game()
		emit_signal("manual_mode_change", false)
		start_countdown("tutorial-timer-countdown")
	elif identifier.begins_with("tutorial-empty"):
		unpause_game()
	else:
		start_countdown()
