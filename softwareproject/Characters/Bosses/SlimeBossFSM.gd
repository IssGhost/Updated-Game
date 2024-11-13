extends FiniteStateMachine1

var can_jump: bool = false

@onready var jump_timer: Timer = parent.get_node("JumpTimer")
@onready var hitbox: Area2D = parent.get_node("Hitbox")


func _init() -> void:
	_add_state("idle")
	_add_state("jump")
	_add_state("hurt")
	_add_state("dead")
	
	
func _ready() -> void:
	set_state(states.idle)
	
	
func _state_logic(_delta: float) -> void:
	if state == states.jump:
		parent.chase()
		parent.move()
		
		
func _get_transition() -> int:
	match state:
		states.idle:
			if can_jump:
				return states.jump
		states.jump:
			if not animation_player.is_playing():
				return states.idle
		states.hurt:
			if not animation_player.is_playing():
				return states.idle
	return -1
	
	
func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.jump:
			if is_instance_valid(parent.player):
				# Generate a random jump direction in X or Y (or both)
				var direction: Vector2 = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

				# Set the velocity for the jump based on the direction and jump force
				parent.velocity = direction * parent.jump_force  # Assuming `jump_force` is defined in the parent for jump power

				# Update path for the hitbox and direction handling
				parent.path = [parent.global_position, parent.global_position + parent.velocity]
				hitbox.knockback_direction = direction
			animation_player.play("jump")
		states.hurt:
			animation_player.play("hurt")
		states.dead:
			animation_player.play("dead")

			
			
func _exit_state(state_exited: int) -> void:
	if state_exited == states.jump:
		can_jump = false
		jump_timer.start()
		#velocity = Vector2.ZERO  # Reset velocity after landing


func _on_JumpTimer_timeout() -> void:
	can_jump = true
