extends Node
class_name SlimeBossFSM

# Configurable variables
@export var jump_cooldown: float = 2.0
@export var slide_attack_speed: float = 20
@export var projectile_scene: PackedScene = preload("res://Weapons/Projectile.tscn")

# References
@onready var parent: SlimeBoss = get_parent()  # Explicitly reference SlimeBoss
@onready var sprite: AnimatedSprite2D = parent.get_node("AnimatedSprite2D")
@onready var jump_timer: Timer = parent.get_node("JumpTimer")
@onready var navigation_agent: NavigationAgent2D = parent.get_node("NavigationAgent2D")

# State management
var states: Dictionary = {}
var previous_state: int = -1
var state: int = -1

func _ready() -> void:
	# Initialize states
	_add_state("idle")
	_add_state("chase")
	_add_state("jump")
	_add_state("attack_slide")
	_add_state("attack_projectile")
	_add_state("hurt")
	_add_state("dead")
	
	# Start the FSM
	set_state(states.idle)
	jump_timer.start(jump_cooldown)

func _physics_process(delta: float) -> void:
	if state != -1:
		_state_logic(delta)
		var transition: int = _get_transition()
		if transition != -1:
			set_state(transition)

# Main state logic
func _state_logic(delta: float) -> void:
	match state:
		states.idle:
			_wander_randomly()
		states.chase:
			_chase_player()
		states.jump:
			_execute_jump()
		states.attack_slide:
			_perform_slide_attack()
		states.attack_projectile:
			_perform_projectile_attack()
		states.hurt:
			pass  # Hurt handled in parent
		states.dead:
			pass  # Dead logic handled by parent

# Transition logic
func _get_transition() -> int:
	match state:
		states.idle:
			if jump_timer.time_left == 0:
				return states.jump
			if _is_player_close():
				return states.chase
		states.chase:
			if !navigation_agent.is_target_reached():
				return states.jump
			if !_is_player_close():
				return states.idle
		states.jump:
			if !sprite.is_playing():
				return states.chase
		states.hurt:
			if !sprite.is_playing():
				return states.idle
		states.dead:
			return -1  # Stay in dead state
	return -1

# Add state to the dictionary
func _add_state(new_state: String) -> void:
	states[new_state] = states.size()

# Change FSM state
func set_state(new_state: int) -> void:
	_exit_state(state)
	previous_state = state
	state = new_state
	_enter_state(previous_state, state)

# Enter a state
func _enter_state(previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			sprite.play("idle")
		states.chase:
			sprite.play("walk")
		states.jump:
			_execute_jump()
		states.attack_slide:
			_perform_slide_attack()
		states.attack_projectile:
			_perform_projectile_attack()
		states.hurt:
			sprite.play("hurt")
		states.dead:
			sprite.play("dead")


# Exit a state
func _exit_state(state_exited: int) -> void:
	if state_exited == states.jump:
		parent.velocity = Vector2.ZERO

# Random wandering in idle state
func _wander_randomly() -> void:
	if navigation_agent.is_target_reached():
		var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		parent.mov_direction = random_direction * parent.max_speed

# Execute jump towards the player
func _execute_jump() -> void:
	navigation_agent.target_position = parent.player.global_position
	var target_position = navigation_agent.get_next_path_position()

	if navigation_agent.is_target_reached() or target_position == parent.global_position:
		#print("No valid path to the player.")
		return

	var direction = (target_position - parent.global_position).normalized()
	if direction == Vector2.ZERO:
		#print("Direction is zero, unable to jump.")
		return

	parent.velocity = direction * parent.jump_force
	#print("Jumping towards:", target_position, "with direction:", direction)

# Chase the player
func _chase_player() -> void:
	navigation_agent.target_position = parent.player.global_position
	if !navigation_agent.is_target_reached():
		var vector_to_next_point = navigation_agent.get_next_path_position() - parent.global_position
		parent.mov_direction = vector_to_next_point.normalized() * parent.max_speed

		# Flip the AnimatedSprite2D based on direction
		if vector_to_next_point.x > 0:
			parent.sprite.flip_h = false
		elif vector_to_next_point.x < 0:
			parent.sprite.flip_h = true
	else:
		parent.mov_direction = Vector2.ZERO

# Perform slide attack
func _perform_slide_attack() -> void:
	if _is_player_close():
		parent.velocity = (parent.player.global_position - parent.global_position).normalized() * slide_attack_speed

# Perform projectile attack
func _perform_projectile_attack() -> void:
	if _is_player_close():
		var projectile = projectile_scene.instantiate()
		parent.get_parent().add_child(projectile)
		projectile.global_position = parent.global_position
		projectile.direction = (parent.player.global_position - parent.global_position).normalized()

# Helper to check if the player is within a certain range
func _is_player_close() -> bool:
	return parent.player and parent.global_position.distance_to(parent.player.global_position) < 300
