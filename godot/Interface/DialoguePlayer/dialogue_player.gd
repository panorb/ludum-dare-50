extends Control

onready var text_label = get_node("Content/TextLabel")

var _line_template = "[center]%s[/center]"
var _identifier = ""
var _line_index = 0
var _lines = []

signal finished(identifier)

func play_dialogue(identifier: String, lines: Array):
	visible = true
	_identifier = identifier
	_line_index = 0
	_lines = lines
	
	_update_label()

func _input(event):
	if _identifier and event.is_action_pressed("ui_accept"):
		next_line()

func next_line():
	_line_index += 1
	
	if _line_index <len(_lines):
		_update_label()
	elif _line_index == len(_lines):
		text_label.text = ""
		visible = false
		emit_signal("finished", _identifier)
		_identifier = ""

func _update_label():
	text_label.bbcode_text = _line_template % _lines[_line_index]
