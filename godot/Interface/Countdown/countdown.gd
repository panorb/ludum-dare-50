extends Control

onready var tween = get_node("Tween")
onready var background = get_node("Background")
onready var labels = get_node("CenterContainer").get_children()
onready var countdown_sound = get_node("Sounds/Countdown")

var time_left := 1000.0
var _identifier := ""

signal finished(identifier)

var digit := 4
var time_since_last_digit := 0.0

func start(identifier := ""):
	_identifier = identifier
	background.visible = true
	digit = 3
	countdown_sound.play()
	
	tween.remove_all()
	tween.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.8, Tween.TRANS_EXPO)
	tween.start()

func _process(delta):
	if digit >= 4 or digit < -1:
		return
	
	time_since_last_digit += delta
	if (time_since_last_digit >= 0.7):
		time_since_last_digit = 0.0
		digit -= 1
		
		if digit >= 0:
			countdown_sound.play()
	
	for label in labels:
		label.visible = label.name.ends_with(str(digit))
	
	if digit == 0:
		tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.2, Tween.TRANS_EXPO)
		tween.start()
		emit_signal("finished", _identifier)
