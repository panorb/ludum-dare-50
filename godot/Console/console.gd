extends Node

onready var input = get_node("Input")
onready var display = get_node("VBoxContainer/Display")

var shell_template = "[color=#16c60c]λ[/color] [color=#cccccc]%s[/color]"

signal command_sent(command)

func _ready():
	display.bbcode_text = shell_template % ""

func _process(_delta):
	input.grab_focus()

func _on_Input_text_changed(new_text):
	display.bbcode_text = shell_template % new_text

func _on_Input_text_entered(new_text):
	input.text = ""
	_on_Input_text_changed("")
	
	emit_signal("command_sent", new_text)
