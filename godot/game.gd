extends Node2D

onready var sequence_manager = get_node("SequenceManager")

onready var world = get_node("World")
onready var robot = get_node("Robot")

onready var dialogue_player = get_node("ViewportContainer/Viewport/DialoguePlayer")
onready var console = get_node("ViewportContainer/Viewport/Console")
onready var countdown = get_node("ViewportContainer/Viewport/Countdown")

onready var tick_sound = get_node("Sounds/Tick")
onready var game_over_sound = get_node("Sounds/GameOver")

var paused := false
var manual := true # Ticks are requested after command input automatically

var tick_interval = 1.0
var time_since_last_tick = 0.0

var allow_respawning = true

func _ready():
	countdown.connect("finished", sequence_manager, "_on_Countdown_finished")
	dialogue_player.connect("finished", sequence_manager, "_on_Dialogue_finished")
	
	sequence_manager.connect("tick_interval_update", self, "_on_SequenceManager_tick_interval_update")
	sequence_manager.connect("dialogue_play", self, "_on_SequenceManager_dialogue_play")
	sequence_manager.connect("countdown_start", self, "_on_SequenceManager_countdown_start")
	sequence_manager.connect("pause_mode_change", self, "_on_SequenceManager_pause_mode_change")
	sequence_manager.connect("manual_mode_change", self, "_on_SequenceManager_manual_mode_change")
	sequence_manager.connect("level_change", self, "_on_SequenceManager_level_change")
	sequence_manager.connect("exit_ready", self, "_on_SequenceManager_exit_ready")


func _on_SequenceManager_tick_interval_update(tick_interval):
	self.time_since_last_tick = 0.0
	self.tick_interval = tick_interval

func _on_SequenceManager_dialogue_play(args):
	# TODO: Implement dialogue
	dialogue_player.play_dialogue(args[0], args[1])

func _on_SequenceManager_countdown_start(identifier):
	countdown.start()

func _on_SequenceManager_manual_mode_change(state):
	manual = state

func _on_SequenceManager_pause_mode_change(state):
	paused = state
	console.enabled = not state

func _on_SequenceManager_level_change(level):
	world.transition_level(level)

func _on_SequenceManager_exit_ready():
	world.spawn_exit(robot.get_tile_position())

func make_tick() -> void:
	time_since_last_tick = 0.0
	
	# First handle world tick then handle robot tick
	world.handle_tick()
	robot.handle_tick()
	
	sequence_manager.handle_tick(world.level_stats)

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
		robot.wrap_around(target_tile)
	elif tile_type == "blocked":
		robot.crash(target_tile)
		
		paused = true
		
		game_over_sound.play()
		
		if allow_respawning and world.respawn_point:
			yield(get_tree().create_timer(1.0), "timeout")
			robot.respawn(world.respawn_point)
			world.reload_level()
			countdown.start()
		else:
			console.enabled = false
			console.display.text = "Game over."
	else:
		if tile_type == "exit":
			sequence_manager.handle_exit()
		
		tick_sound.play()
	
		robot.movement(target_tile)


func _on_Console_command_sent(command):
	if paused:
		return
	
	robot.execute_command(command)
	
	if manual and command in ["left", "right", "up", 
	"down"]:
		make_tick()
