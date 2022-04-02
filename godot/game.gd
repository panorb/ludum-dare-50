extends Node2D

onready var robot = get_node("Robot")

onready var tick_sound = get_node("Sounds/Tick")

var tick_interval = 2.0
var time_since_last_tick = 0.0

func _process(delta):
	time_since_last_tick += delta
	
	if time_since_last_tick >= tick_interval and tick_interval != 0.0:
		time_since_last_tick = 0.0
		tick_sound.play()
		robot.handle_tick()
	
