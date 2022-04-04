extends Node

signal tick_interval_update(tick_interval)
signal dialogue_play(identifier, lines)
signal countdown_start(identifier)
signal pause_mode_change(state)
signal manual_mode_change(state)
signal level_change(level)
signal exit_ready

func _ready():
	yield(get_tree(), "idle_frame")
	
	change_level("tutorial_start")

# Gets called every tick
func handle_tick(level_stats: Dictionary):
	var objective_achieved = level_objective_achieved(level_stats)
	var level_name = level_stats["name"]
	
	if level_name == "tutorial_start":
		if level_stats["level_ticks"] == 1:
			play_dialogue("tutorial-start-2", ["Okay. Again. Enter [left, right, up, down] and press enter."])
		if level_stats["level_ticks"] == 2:
			play_dialogue("tutorial-start-3", ["...",
											"Once more... a direction you haven't tried yet. [left, right, up, down] and then enter."])
		if level_stats["level_ticks"] == 3:
			play_dialogue("tutorial-start-4", ["Alright.",
												"From now on the robot will move forward automatically...",
												"At a time interval we will call 'tick' from now on.",
												"Let's start with 1 tick per second. Steer for a bit.",
												"[left, right, up, down] and then enter to change direction!"])
		if level_stats["level_ticks"] == 14:
			play_dialogue("tutorial-start-end", ["Hope you got that. Lets go a bit faster now.",
												"Get over to that '[color=#5d7643]>[/color]' tile I opened for you."])
			update_tick_interval(0.8)
	
	if level_name == "tutorial_wall":
		if level_stats["close_to_wall_ticks"] == 3:
			level_stats["close_to_wall_ticks"] += 1
			play_dialogue("tutorial-wall-end", ["Good enough.",
												"Move over to the '[color=#5d7643]>[/color]' exit again."])
	
	if level_name == "tutorial_timer":
		if level_stats["passed_timer_fields"] == 3:
			level_stats["passed_timer_fields"] += 1
			play_dialogue("tutorial-timer-end", ["Okay.",
												"Onto the exit it is!"])
	
	if level_name == "tutorial_only_once":
		if level_stats["passed_only_once_fields"] == 8:
			level_stats["passed_only_once_fields"] += 1
			play_dialogue("tutorial-only-once-end", ["I think you got it.",
												"Time to exit this place."])
	
	
	if level_name in game_levels and level_stats["level_ticks"] % 35 == 0:
		played_levels += 1
	
	if objective_achieved:
		if level_name.begins_with("tutorial"):
			emit_signal("exit_ready")
		else:
			change_level(get_random_next_level(level_name))
		return null # Do not update level stats when finishing level, otherwise they carry over between levels
	
	return level_stats # Update level stats to ensure that dialogue doesn't trigger twice

# Gets called when player enters exit tile
func handle_exit(level_stats: Dictionary):
	var level_name = level_stats["name"]
	if level_name in game_levels:
		pass
	
	pause_game()
	
	if level_name == "tutorial_start":
		change_level("tutorial_wall")
	if level_name == "tutorial_wall":
		change_level("tutorial_timer")
	if level_name == "tutorial_timer":
		play_dialogue("tutorial-only-once-1", ["This is taking too long. Let's speed up the ticks a bit.",
											"... Done... Okay, where were we?..."])
	if level_name == "tutorial_only_once":
		change_level("tutorial_wrap_around")
	if level_name == "tutorial_wrap_around":
		play_dialogue("tutorial-finish", ["Alright... and with that...",
										"I taught you everything there is to know.",
										"Now good luck with the real deal:",
										"Survive as long as you can."])

# left - minimum excitement for the level to be in the level pool
# right - weight that the level should get when determing the random next level

# mimimum_levels, maximum_levels, weight, minimum_ticks, maximum_ticks
var game_levels = {
	"walled_basic": [0, 1, 2, 4, 8],
	"cross_basic": [0, 6, 2, 6, 10],
	"connections_basic": [2, 10, 4, 6, 12],
	"labyrinth_basic" : [2, -1, 3, 10, 18],
	"labyrinth_variant" : [3, -1, 3, 18, 24],
	"labyrinth2_basic": [7, 16, 2, 8, 18],
	"labyrinth2_variant": [9, -1, 3, 16, 20],
	"ludum_dare_basic": [4, 15, 1, 3, 5],
	"outer_circle": [4, -1, 3, 6, 12],
	"snake_basic": [8,-1, 5, 8, 14],
	"snake_variant": [8, -1, 5, 8, 14],
	"cross_target": [10, -1, 4, 14, 18],
	"small_left": [12, -1, 3, 4, 10],
	"small_center": [12, -1, 3, 4, 10],
	"small_right": [12, -1, 3, 4, 10],
	"walled_tnt_run": [14, -1, 6, 16, 28],
	"dance_basic": [18, -1, 6, 6, 16],
	"shooter_basic": [22, -1, 4, 4, 10],
	"graveyard_basic": [0, 12, 5, 15, 20]
}

var played_levels = 0
var target_ticks = 0

func restart() -> void:
	played_levels = 0
	change_level("game_start")

func _on_World_level_changed(level_stats : Dictionary) -> void:
	var level_name : String = level_stats["name"]
	
	if level_name in game_levels:
		var min_ticks = game_levels[level_name][3]
		var max_ticks = game_levels[level_name][4]
		target_ticks = randi() % max_ticks + min_ticks
		
		played_levels += 1
	
	if not level_name.begins_with("tutorial"):
		emit_signal("manual_mode_change", false)
		
		if played_levels >= 0:
			update_tick_interval(0.7)
		elif played_levels >= 6:
			update_tick_interval(0.65)
		elif played_levels >= 12:
			update_tick_interval(0.6)
		elif played_levels >= 18:
			update_tick_interval(0.55)
		elif played_levels >= 26:
			update_tick_interval(0.5)
		elif played_levels >= 40:
			update_tick_interval(0.45)
	else:
		if level_name == "tutorial_start":
			play_dialogue("tutorial-start-1", [
				"...",
				"...........",
				"Okay. Let's get this over with... *sigh*",
				"Hello human. My name is 'Computer Scientist'.",
				"And this is the training for AI 87416 you signed up for.",
				"You will provide part of a dataset that will be used to train a self steering robot.",
				"To control the robot you will use the terminal before you.",
				"...",
				"Let's start simple.",
				"Enter a direction into the terminal [left, right, up, down] and press enter."
			])
		if level_name == "tutorial_wall":
			play_dialogue("tutorial-wall", ["Now.... Let's go over the tile types one by one.",
										"First up... Walls. Don't crash into them. *shrug*",
										"Let's practice that for a bit by moving close to a wall.",
										"Hug the wall for a bit... Without crashing."])
		if level_name == "tutorial_timer":
			play_dialogue("tutorial-timer", ["Um.. *these* blocks... They count down every tick...",
										"When they reach 0 they act like a wall for one tick.",
										"Move over a few of these tiles without crashing."])
		if level_name == "tutorial_only_once":
			play_dialogue("tutorial-only-once-2", ["These pipes are unstable. They'll only hold your weight once."])
			update_tick_interval(0.6)
		if level_name == "tutorial_wrap_around":
			play_dialogue("tutorial-wrap-around", ["Maybe you noticed by now. Maybe you didn't.",
												"If you exit the level on one side you come out on the other!"])

func get_random_next_level(current_level : String):
	var pool = []
	
	for level in game_levels:
		var stats = game_levels[level]
		
		# If level is of the same type dont add it - to avoid repetition
		if (level.split("_")[0] == current_level.split("_")[0]):
			continue
		
		if played_levels >= stats[0] and (stats[1] == -1 or played_levels <= stats[1]):
			for i in range(stats[2]):
				pool.append(level)
	
	print(pool)
	
	# Pick a random level out of the level pool
	return pool[randi() % pool.size()]

# Checks if the objective for the current level are achieved
func level_objective_achieved(level_stats: Dictionary) -> bool:
	var level_name = level_stats["name"]
	
	if level_name == "tutorial_start":
		return level_stats["level_ticks"] >= 14
	if level_name == "tutorial_wall":
		return level_stats["close_to_wall_ticks"] >= 3
	if level_name == "tutorial_timer":
		return level_stats["passed_timer_fields"] >= 3
	if level_name == "tutorial_only_once":
		return level_stats["passed_only_once_fields"] >= 8
	if level_name == "tutorial_wrap_around":
		return true
	if level_name == "game_start":
		return level_stats["level_ticks"] >= 2

	return level_stats["level_ticks"] >= target_ticks

func update_tick_interval(tick_interval : float) -> void:
	emit_signal("tick_interval_update", tick_interval)

func pause_game() -> void:
	emit_signal("pause_mode_change", true)

func unpause_game() -> void:
	emit_signal("pause_mode_change", false)

func start_countdown(identifier := ""):
	emit_signal("countdown_start", identifier)

func play_dialogue(identifier: String, lines: Array):
	pause_game()
	emit_signal("dialogue_play", [identifier, lines])

func change_level(level_name: String):
	emit_signal("level_change", level_name)

func _on_Countdown_finished(identifier : String):
	unpause_game()

func _on_Dialogue_finished(identifier : String):
	if identifier == "tutorial-start-4":
		pause_game()
		emit_signal("manual_mode_change", false)
		start_countdown("tutorial-timer-countdown")
	elif identifier == "tutorial-only-once-1":
		change_level("tutorial_only_once")
	elif identifier == "tutorial-finish":
		change_level("game_start")
		start_countdown()
	elif identifier.begins_with("tutorial-start"):
		unpause_game()
	else:
		start_countdown()
