extends AnimatedSprite

func _on_TileTransition_animation_finished():
	stop()
	queue_free()
