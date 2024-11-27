extends AudioStreamPlayer


func _on_slimeboss_defeated() -> void:
	if playing:
		stop()
		print("Music stopped as the boss is defeated.")
