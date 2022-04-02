extends Label

func _process(_delta):
	var p : Node = get_tree().root.get_node("Game")
	self.text = "Tick: " + str(p.tick_interval - p.time_since_last_tick)
