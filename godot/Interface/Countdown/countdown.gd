extends Control

onready var background = get_node("Background")
onready var labels = get_node("CenterContainer").get_children()
var time_left := 1000.0
var _identifier := ""

signal finished(identifier)

func start(identifier := ""):
	_identifier = identifier
	background.visible = true
	time_left = 4.0

func _process(delta):
	if time_left == 1000.0:
		return
	
	time_left -= delta
	
	if time_left <= 3.0:
		for label in labels:
			label.visible = label.name.ends_with(int(ceil(time_left)))
	if time_left <= -1.0:
		background.visible = false
		time_left = 1000.0
		emit_signal("finished", _identifier)
