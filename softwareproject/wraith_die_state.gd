extends State

@export var drop_item_scene: PackedScene = preload("res://Scenes/coin.tscn")
@export var drop_chance: float = 1.0

func enter_state(_prev_state: State):
	if actor.is_dead:
		print("Entering DieState")

		# Stop all animations before playing death animation
		actor.animator.stop()
		actor.velocity = Vector2.ZERO
		actor.set_physics_process(false)

		match actor.last_direction:
			Vector2.UP:
				actor.animator.play("die_left")
			Vector2.DOWN:
				actor.animator.play("die_right")
			Vector2.LEFT:
				actor.animator.play("die_left")
			Vector2.RIGHT:
				actor.animator.play("die_right")
			_:
				actor.animator.play("die_right")

		# Connect the animation_finished signal for cleanup
		if not actor.animator.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
			actor.animator.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func drop_item():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	if rng.randi_range(0, 100) < drop_chance * 100:
		print("Dropping a coin!")
		if drop_item_scene:
			var coin = drop_item_scene.instantiate()
			coin.global_position = actor.global_position  # Drop the coin at the Wraith's position
			actor.get_tree().current_scene.add_child(coin)
		else:
			print("Error: drop_item_scene is not set!")
	else:
		print("No coin dropped.")
		
func _on_death_animation_finished(anim_name: String):
	if anim_name in ["die_right", "die_left", "die_down", "die_up"]:
		print("Wraith defeated. Emitting defeated signal and removing from scene.")
		drop_item()
		actor.emit_signal("defeated")
		actor.queue_free()  # Remove the enemy from the scene
