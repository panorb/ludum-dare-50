extends Control

onready var tween : Tween = get_node("Tween")
onready var character_tween : Tween = get_node("Character/Tween")

onready var character = get_node("Character")
onready var continue_indicator = get_node("Background/ColorRect/ContinueIndicator")
onready var text_label = get_node("Content/TextLabel")
onready var beep_sound = get_node("Sounds/Beep")

var _line_template = "[center]%s[/center]"
var _identifier = ""
var _line_index = 0
var _lines = []

signal finished(identifier)
signal task_update(task_text)

# Grace period where no input is accepted to avoid accidental dialogue skipping
var enter_grace_period = 0.3

func _process(delta):
	enter_grace_period -= delta
	
	if text_label.percent_visible == 1.0:
		continue_indicator.visible = (int(OS.get_ticks_msec() / 600)) % 2 == 0
	else:
		continue_indicator.visible = false

func play_dialogue(identifier: String, lines: Array):
	# character.margin_left = 0
	character_tween.remove_all()
	character_tween.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.8, Tween.TRANS_EXPO)
	character_tween.interpolate_property(character, "margin_left", 0, -202, 0.6, Tween.TRANS_EXPO)
	character_tween.start()
	
	visible = true
	
	_identifier = identifier
	_line_index = 0
	_lines = lines
	
	emit_signal("task_update", "")
	_update_label()

func next_line():
	if not _identifier or enter_grace_period >= 0:
		return
	
	character_tween.interpolate_property(character, "margin_top", -118, -109, 0.34, Tween.TRANS_EXPO)
	character_tween.interpolate_property(character, "margin_left", -211, -202, 0.34, Tween.TRANS_EXPO)
	character_tween.interpolate_property(character, "rect_scale", Vector2(1.05, 1.05), Vector2(1.0, 1.0), 0.34, Tween.TRANS_EXPO)
	character_tween.start()
	
	enter_grace_period = 0.3
	
	_line_index += 1
	
	if _line_index <len(_lines):
		_update_label()
	elif _line_index == len(_lines):
		# text_label.text = ""
		
		character_tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.8, Tween.TRANS_EXPO)
		character_tween.start()
		
		var temp = _identifier
		_identifier = ""
		emit_signal("finished", temp)
		emit_signal("task_update", _lines[_line_index - 1])


func _update_label():
	text_label.percent_visible = 0
	text_label.bbcode_text = _line_template % _lines[_line_index]
	
	beep_sound.play()
	
	tween.remove_all()
	tween.interpolate_property(text_label, "percent_visible", 0.0, 1.0, len(text_label.text) * 0.02)
	tween.start()


func _on_Beep_finished():
	yield(get_tree().create_timer(0.12), "timeout")
	
	if modulate != Color(1, 1, 1, 0) and text_label.percent_visible != 1.0:
		beep_sound.play()
	
	# 
		
