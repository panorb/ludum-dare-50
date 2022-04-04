extends Node

var enabled = true setget set_enabled

onready var input = get_node("Input")
onready var display = get_node("VBoxContainer/Display")
onready var task_label = get_node("VBoxContainer/VBoxContainer/TaskLabel")

var task_template = "[color=#6c6c6c]%s[/color]"

var disabled_template = "[color=#cccccc]λ[/color]"
var shell_template = "[color=#16c60c]λ[/color] [color=#cccccc]%s[/color]"
var caret_visible = false

signal command_sent(command)
signal enter_pressed

func update_task(task_text: String):
	task_label.bbcode_text = task_template % task_text

func _update_text_label():
	if enabled:
		var text = input.text
		if caret_visible:
			text += "█"
		
		display.bbcode_text = shell_template % text
	else:
		display.bbcode_text = disabled_template

func set_enabled(new_val: bool) -> void:
	enabled = new_val
	_update_text_label()

func _ready():
	_update_text_label()

func _process(_delta):
	input.grab_focus()
	input.caret_position = len(input.text)
	
	var new_val = (int(OS.get_ticks_msec() / 600)) % 2 == 0
	
	if enabled and caret_visible != new_val:
		caret_visible = new_val
		_update_text_label()

func _on_Input_text_changed(new_text):
	if " " in new_text:
		input.text = new_text.replace(" ", "")
		return
	
	if enabled:
		_update_text_label()

func _on_Input_text_entered(new_text):
	input.text = ""
	
	if enabled:
		_update_text_label()
		emit_signal("command_sent", new_text)
	else:
		emit_signal("enter_pressed")
