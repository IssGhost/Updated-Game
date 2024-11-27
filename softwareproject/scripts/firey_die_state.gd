extends State

@export var drop_item_scene_coin: PackedScene = preload("res://Scenes/coin.tscn")
@export var drop_item_scene_heart: PackedScene = preload("res://Scenes/heart_item.tscn")
@export var drop_chance: float = 0.1
@export var heart_drop_chance: float = 0.05

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
		drop_item()
		# Connect the animation_finished signal for cleanup
		if not actor.animator.is_connected("animation_finished", Callable(self, "_on_death_animation_finished")):
			actor.animator.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func drop_item():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Check if any item will drop
	if rng.randi_range(0, 100) < drop_chance * 100:
		print("An item will drop!")
		var drop_heart = rng.randi_range(0, 100) < heart_drop_chance * 100

		if drop_heart and drop_item_scene_heart:
			print("Dropping a heart!")
			var heart = drop_item_scene_heart.instantiate()
			heart.global_position = actor.global_position  # Drop the heart at the actor's position
			actor.get_tree().current_scene.add_child(heart)
		elif drop_item_scene_coin:
			print("Dropping a coin!")
			var coin = drop_item_scene_coin.instantiate()
			coin.global_position = actor.global_position  # Drop the coin at the actor's position
			actor.get_tree().current_scene.add_child(coin)
		else:
			print("Error: Neither drop_item_scene_coin nor drop_item_scene_heart is set!")
	else:
		print("No item dropped.")
		
func _on_death_animation_finished(anim_name: String):
	if anim_name in ["die_right", "die_left", "die_down", "die_up"]:
		print("Firery defeated. Emitting defeated signal and removing from scene.")
		actor.emit_signal("defeated")
		actor.queue_free()  # Remove the enemy from the scene
