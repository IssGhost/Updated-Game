extends State

func enter_state(_prev_state: State):
	print("Entering DieState")
	
	# Play the death animation based on the direction the Wraith was facing
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
			actor.animator.play("die_right")  # Default animation

	# Stop the Wraith from moving
	actor.velocity = Vector2.ZERO
	actor.set_physics_process(false)  # Stop physics processing
	
	# Connect to the animation_finished signal, if not already connected
	if not actor.animator.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
		actor.animator.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func exit_state():
	print("Exiting DieState")  # This will help track state transitions

func _on_death_animation_finished(anim_name: String):
	if anim_name in ["die_right", "die_left", "die_down", "die_up"]:
		print("Wraith defeated. Emitting defeated signal and preparing to remove from scene.")
		
		# Emit the defeated signal first
		actor.emit_signal("defeated")

		# Wait a couple of frames to ensure propagation
		await get_tree().process_frame
		await get_tree().process_frame

		# Now safely remove the Wraith from the scene
		actor.queue_free()
