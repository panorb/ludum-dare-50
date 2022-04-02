extends Node2D

onready var tile_layer = get_node("Tile Layer")

func get_tile_type(tile : Vector2):
	var tile_id = tile_layer.get_cell(int(tile.x), int(tile.y))
	
	if tile_id == -1:
		return "void"
	elif tile_id == 1:
		return "empty"
	else:
		return "blocked"
