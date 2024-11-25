extends FiniteStateMachine1

var can_jump: bool = false

@onready var jump_timer: Timer = $JumpTimer
@onready var hitbox: Area2D = $Hitbox
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

func _init() -> void:
	_add_state("idle")
	_add_state("jump")
	_add_state("chase")
	_add_state("hurt")
	_add_state("dead")
	_add_state("attack_slide")
	_add_state("attack_projectile")

func _ready() -> void:
	set_state(states.idle)

func _state_logic(_delta: float) -> void:
	match state:
		states.idle:
#			_wander_randomly()
			pass
		states.jump:
			_execute_jump()
		states.chase:
			parent.chase()  # Use the inherited chase logic from Enemy
		states.attack_slide:
			_perform_slide_attack()
		states.attack_projectile:
			_perform_projectile_attack()

func _get_transition() -> int:
	match state:
		states.idle:
			if can_jump:
				return states.jump
			if is_player_close():
				return states.chase
		states.chase:
			if not is_player_close():
				return states.idle
		states.jump:
			if not animation_player.is_playing():
				return states.idle
		states.hurt:
			if not animation_player.is_playing():
				return states.idle
		states.dead:
			return -1
	return -1

func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.jump:
			animation_player.play("jump")
		states.chase:
			animation_player.play("chase")
		states.attack_slide:
			animation_player.play("slide_attack")
		states.attack_projectile:
			animation_player.play("projectile_attack")
		states.hurt:
			animation_player.play("hurt")
		states.dead:
			animation_player.play("dead")

#func _wander_randomly():
	#if navigation_agent.path.is_empty():
		## Move randomly in idle
		#var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		#parent.mov_direction = random_direction * parent.max_speed

func is_player_close() -> bool:
	return parent.player and parent.global_position.distance_to(parent.player.global_position) < 300

func _execute_jump():
	if is_player_close():
		var direction = (parent.player.global_position - parent.global_position).normalized()
		parent.velocity = direction * parent.jump_force

func _perform_slide_attack():
	if is_player_close():
		parent.velocity = (parent.player.global_position - parent.global_position).normalized() * 200

func _perform_projectile_attack():
	if is_player_close():
		var projectile_scene = preload("res://Weapons/Projectile.tscn")
		var projectile = projectile_scene.instance()
		get_parent().add_child(projectile)
		projectile.global_position = parent.global_position
		projectile.direction = (parent.player.global_position - parent.global_position).normalized()
