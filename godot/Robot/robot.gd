extends Position2D

onready var tween = get_node("Tween")
onready var sprite = get_node("Sprite")

var velocity := Vector2(1, 0) # Start orientation: right
signal move_intent(target_tile)

func get_tile_position():
	return self.transform.get_origin() / 32.0

func handle_tick():
	var target_tile : Vector2 = get_tile_position() + velocity
	emit_signal("move_intent", target_tile)

func wrap_around(target_tile : Vector2):
	self.position = (target_tile - (velocity * Vector2(18, 9))) * 32.0

func movement(target_tile : Vector2):
	self.position = target_tile * 32.0
	tween.interpolate_property(sprite, "scale", Vector2(1.05, 1.05), Vector2(1.0, 1.0), 0.5, Tween.TRANS_EXPO)
	tween.start()

func crash(_target_tile : Vector2):
	pass

func execute_command(command : String) -> void:
	if (command == "up"):
		self.velocity = Vector2(0, -1)
		sprite.rotation_degrees = -90
	
	if (command == "down"):
		self.velocity = Vector2(0, 1)
		sprite.rotation_degrees = 90
	
	if (command == "left"):
		self.velocity = Vector2(-1, 0)
		sprite.rotation_degrees = 180
	
	if (command == "right"):
		self.velocity = Vector2(1, 0)
		sprite.rotation_degrees = 0
