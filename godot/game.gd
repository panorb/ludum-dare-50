extends Node2D

onready var level = get_node("Level")
onready var robot = get_node("Robot")

onready var tick_sound = get_node("Sounds/Tick")

var tick_interval = 1.0
var time_since_last_tick = 0.0

func _process(delta):
	time_since_last_tick += delta
	
	if time_since_last_tick >= tick_interval and tick_interval != 0.0:
		time_since_last_tick = 0.0
		tick_sound.play()
		robot.handle_tick()

func _on_Robot_move_intent(target_tile):
	var tile_type : String = level.get_tile_type(target_tile)
	
	if tile_type == "void":
		robot.wrap_around(target_tile)
	elif tile_type == "empty":
		robot.movement(target_tile)
	elif tile_type == "blocked":
		robot.crash(target_tile)


func _on_Console_command_sent(command):
	robot.execute_command(command)
