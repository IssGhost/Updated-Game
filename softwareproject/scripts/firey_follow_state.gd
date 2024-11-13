extends State
class_name FireyFollowState

var speed: float = 75.0

func enter_state(_previous_state: State):
	print("Entering FollowState - Player should be detected if in range")
	if actor.player_in_range:
		print("Player confirmed in range; following...")


func physics_update(delta: float):
	if actor.player_in_attack_range:
		print("Player in attack range, transitioning to AttackState")
		transition.emit("AttackState")
		return  # Ensures it doesn't continue with the follow behavior
	
	# Regular follow behavior if not in attack range
	if actor.player:
		var direction = (actor.player.global_position - actor.global_position).normalized()
		actor.velocity = direction * speed
		actor.move_and_slide()
		
		# Fallback for exiting the state if player is out of range
		if not actor.player_in_range:
			transition.emit("RunState")

func move_and_play_animation(direction: Vector2):
	if direction.y < 0:
		actor.animator.play("walk_up")
	elif direction.y > 0:
		actor.animator.play("walk_down")
	elif direction.x < 0:
		actor.animator.play("walk_left")
	elif direction.x > 0:
		actor.animator.play("walk_right")

func exit_state():
	actor.velocity = Vector2.ZERO
	print("Exiting FollowState")
