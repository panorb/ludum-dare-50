extends Node2D

onready var sequence_manager = get_node("SequenceManager")

onready var world = get_node("World")
onready var robot = get_node("Robot")

onready var dialogue_player = get_node("ViewportContainer/Viewport/DialoguePlayer")
onready var console = get_node("ViewportContainer/Viewport/Console")
onready var countdown = get_node("ViewportContainer/Viewport/Countdown")

onready var tick_sound = get_node("Sounds/Tick")
onready var game_over_sound = get_node("Sounds/GameOver")
onready var respawn_sound = get_node("Sounds/Respawn")
onready var error_sound = get_node("Sounds/Error")

var paused := false
var manual := true # Ticks are requested after command input automatically

var tick_interval = 1.0
var time_since_last_tick = 0.0

var current_tick_highscore = 0
var ticks_since_start = -1

var allow_respawning = true
var allow_restart = false

func _ready():
	world.connect("level_changed", sequence_manager, "_on_World_level_changed")
	countdown.connect("finished", sequence_manager, "_on_Countdown_finished")
	dialogue_player.connect("finished", sequence_manager, "_on_Dialogue_finished")
	dialogue_player.connect("task_update", console, "update_task")
	console.connect("enter_pressed", dialogue_player, "next_line")
	
	world.connect("level_changed", self, "_on_World_level_changed")
	
	console.connect("command_sent", self, "_on_Console_command_sent")
	console.connect("enter_pressed", self, "_on_Console_enter_hit")
	
	sequence_manager.connect("tick_interval_update", self, "_on_SequenceManager_tick_interval_update")
	sequence_manager.connect("dialogue_play", self, "_on_SequenceManager_dialogue_play")
	sequence_manager.connect("countdown_start", self, "_on_SequenceManager_countdown_start")
	sequence_manager.connect("pause_mode_change", self, "_on_SequenceManager_pause_mode_change")
	sequence_manager.connect("manual_mode_change", self, "_on_SequenceManager_manual_mode_change")
	sequence_manager.connect("level_change", self, "_on_SequenceManager_level_change")
	sequence_manager.connect("exit_ready", self, "_on_SequenceManager_exit_ready")

func _on_World_level_changed(level_stats : Dictionary) -> void:
	time_since_last_tick = -0.4

func _on_SequenceManager_tick_interval_update(tick_interval):
	if self.tick_interval != tick_interval:
		self.time_since_last_tick = 0.0
		self.tick_interval = tick_interval

func _on_SequenceManager_dialogue_play(args):
	dialogue_player.play_dialogue(args[0], args[1])

func _on_SequenceManager_countdown_start(identifier):
	countdown.start()

func _on_SequenceManager_manual_mode_change(state):
	manual = state

func _on_SequenceManager_pause_mode_change(state):
	paused = state
	console.enabled = not state

func _on_SequenceManager_level_change(level):
	if not robot.is_alive():
		return
	
	world.transition_level(level, robot.get_tile_position(), robot.velocity)
	
	if world.current_level == "game_start":
		allow_restart = false
		ticks_since_start = 0

func _on_SequenceManager_exit_ready():
	world.spawn_exit(robot.get_tile_position())

func make_tick() -> void:
	time_since_last_tick = 0.0
	
	if ticks_since_start != -1:
		ticks_since_start += 1
		
		console.update_task("Survive as long as you can. Survived [color=#91a47a]" + str(ticks_since_start) + "[/color] ticks so far.")
	
	# First handle world tick then handle robot tick
	world.handle_tick()
	robot.handle_tick()
	
	var updated_stats = sequence_manager.handle_tick(world.level_stats)
	if updated_stats:
		world.level_stats = updated_stats

func _process(delta):
	if not manual and not paused:
		time_since_last_tick += delta
		
		if time_since_last_tick >= tick_interval and tick_interval != 0.0:
			make_tick()

#func _on_Countdown_finished():
#	tick_interval = 1.0
#	time_since_last_tick = 0.0
#	
#	world.load_level("timer_explanation")
#	console.enabled = true

func _on_Robot_move_intent(target_tile):
	var tile_type : String = world.probe_next_tile(target_tile)
	
	if tile_type == "void":
		# Wrap around
		_on_Robot_move_intent(target_tile - (robot.velocity * Vector2(19, 9)))
	elif tile_type == "blocked":
		robot.crash(target_tile)
		
		paused = true
		
		game_over_sound.play()
		
		if allow_respawning and world.respawn_point:
			yield(get_tree().create_timer(1.0), "timeout")
			respawn_sound.play()
			robot.respawn(world.respawn_point)
			world.reload_level()
			sequence_manager._on_World_level_changed(world.level_stats)
		else:
			console.enabled = false
			
			if current_tick_highscore < ticks_since_start:
				current_tick_highscore = ticks_since_start
			
			ticks_since_start = -1
			allow_restart = true
			console.display.bbcode_text = "Game over. Current Highscore: [color=#91a47a]" + str(current_tick_highscore) + "[/color]"
	else:
		if tile_type == "exit":
			sequence_manager.handle_exit(world.level_stats)
		
		tick_sound.play()
	
		robot.movement(target_tile)

func _on_Console_command_sent(command):
	if paused:
		return
	
	robot.execute_command(command)
	
	if command == "skip" and world.current_level.begins_with("tutorial"):
		restart_game()
	elif command in ["left", "right", "up", 
	"down"]:
		if manual:
			make_tick()
	elif command:
		error_sound.play()

func restart_game():
	paused = true
	robot.sprite.frame = 0
	sequence_manager.restart()
	robot.respawn(world.respawn_point)
	world.reload_level()
	console._update_text_label()
	console.update_task("Survive as long as you can.")
	ticks_since_start = 0
	countdown.start()

func _on_Console_enter_hit():
	if allow_restart:
		allow_restart = false
		restart_game()
