extends State


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


func _on_death_animation_finished(anim_name: String):
	if anim_name in ["die_right", "die_left", "die_down", "die_up"]:
		print("Wraith defeated. Emitting defeated signal and removing from scene.")
		actor.emit_signal("defeated")
		actor.queue_free()  # Remove the enemy from the scene
