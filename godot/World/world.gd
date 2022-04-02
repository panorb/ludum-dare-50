extends Node2D

onready var tween = get_node("Tween")
onready var tile_layer = get_node("Tile Layer")

onready var transition_container : Node = get_node("Transitions")
onready var tile_transition : PackedScene = preload("res://World/TileTransition/TileTransition.tscn")

var current_level := "empty"
var available_level_exits : Array = []
var respawn_point = null

# Stats to keep track of
var level_stats := {}

func _ready():
	reload_level()

func reset_level_stats():
	level_stats = {
		"name": current_level, # Name of the current level
		"level_ticks": 0, # Ticks that were already spent in this level
		"passed_only_once_fields": 0, # Number of only once fields that were passed
		"passed_timer_fields": 0, # Number of countdown fields that were passed
		"close_to_wall_ticks": 0 # Ticks that were spent next to a wall
	}

func probe_next_tile(tile : Vector2):
	var tile_id = tile_layer.get_cell(int(tile.x), int(tile.y))
	
	if tile_id == -1:
		return "void"
	elif tile_id == 2 or tile_id == 9 or tile_id == 12:
		return "blocked"
	elif tile_id == 4:
		return "exit"
	else:
		# Only once field
		if tile_id == 11:
			level_stats["passed_only_once_fields"] += 1
			tile_layer.set_cell(int(tile.x), int(tile.y), 12)
		
		if tile_id in [6, 7, 8]:
			level_stats["passed_timer_fields"] += 1
		
		# Determine if close to wall
		var close_to_wall := false
		
		for i in range(-1, 2):
			for j in range(-1, 2):
				if abs(i) == abs(j) or (i == 0 and j == 0):
					continue
				
				var neighbor_cell = tile_layer.get_cell(int(tile.x + i), int(tile.y + j))
				if neighbor_cell == 2:
					close_to_wall = true
		
		if close_to_wall:
			level_stats["close_to_wall_ticks"] += 1
		
		return "empty"

func handle_tick():
	for i in range(19):
		for j in range(9):
			var cell : int = tile_layer.get_cell(i, j)
			
			if cell in [6, 7, 8, 9]:
				tile_layer.set_cell(i, j, 6 + (((cell - 6) + 1) % 4))
	
	tile_layer.update()
	level_stats["level_ticks"] += 1

func spawn_transition(x: int, y: int):
	var transition_instance = tile_transition.instance()
	transition_instance.position = Vector2(x, y) * 32
	transition_container.add_child(transition_instance)
	
func start_transitions():
	for trans in transition_container.get_children():
		trans.playing = true
		yield(get_tree().create_timer(0.00001), "timeout")

func spawn_exit(robot_pos : Vector2):
	if not available_level_exits:
		return
	
	var longest_distance = 0.0
	var longest_exit = available_level_exits[0]
	
	# Find exit with longest distance to player
	for exit_pos in available_level_exits:
		if robot_pos.distance_squared_to(exit_pos) > longest_distance:
			longest_distance = robot_pos.distance_squared_to(exit_pos)
			longest_exit = exit_pos
	
	# Spawn the exit with transition
	if tile_layer.get_cell(longest_exit.x, longest_exit.y) != 4:
		tile_layer.set_cell(longest_exit.x, longest_exit.y, 4)
		spawn_transition(longest_exit.x, longest_exit.y)
	
	# Clear the available exits to avoid double spawning
	available_level_exits.clear()
	
	# Start the transition
	start_transitions()

func load_level(level_name: String, animate := true):
	current_level = level_name
	
	# Reset level stats, exits and respawn point
	reset_level_stats()
	available_level_exits.clear()
	respawn_point = null
	
	var level : Node = load("res://World/Levels/" + level_name + ".tmx").instance()
	var level_layer : TileMap = level.get_node("Tile Layer")
	
	tween.reset_all()
	
	
	for i in range(19):
		for j in range(9):
			var current_cell = tile_layer.get_cell(i, j)
			var level_cell = level_layer.get_cell(i, j)
			
			# Save tutorial exits
			if level_cell == 4:
				available_level_exits.append(Vector2(i, j))
				level_cell = 1
			
			# Save respawn point
			if level_cell == 25:
				respawn_point = Vector2(i, j)
				level_cell = 1
			
			# Update level tiles
			if  current_cell != level_cell:
				tile_layer.set_cell(i, j, level_cell)
				if animate:
					spawn_transition(i, j)
	
	tile_layer.update()
	start_transitions()

func transition_level(level_name : String, animate := true):
	if (current_level == level_name):
		return
		
	load_level(level_name, animate)

func reload_level():
	load_level(current_level, true)

