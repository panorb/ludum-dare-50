extends Sprite

var velocity := Vector2(1, 0) # Start orientation: right
signal move_wanted(to)

func get_tile_position():
	return self.transform.get_origin() / 32.0

func handle_tick():
	self.transform = self.transform.translated(velocity * 32.0)
	print(get_tile_position())

func execute_command(command : String) -> void:
	if (command == "up"):
		velocity = Vector2(0, -1)
	
	if (command == "down"):
		velocity = Vector2(0, 1)
	
	if (command == "left"):
		velocity = Vector2(-1, 0)
	
	if (command == "right"):
		velocity = Vector2(1, 0)
