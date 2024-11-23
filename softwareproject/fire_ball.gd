extends CharacterBody2D

signal defeated  # Define the defeated signal

# Health properties
@export var max_health: int = 50
var current_health: int = max_health

# Track if the character is dead
var is_dead: bool = false  # Prevents repeated death triggers

# Movement speed and other properties
@export var speed: float = 100.0
@export var invul_duration: float = 1.0
var is_invulnerable: bool = false
var player_in_attack_range: bool = false
var last_direction: Vector2 = Vector2.DOWN
var current_direction: Vector2 = Vector2.ZERO
@export var min_distance_to_player: float = 100.0
@export var attack_range: float = 100.0
var player: Node2D = null
var player_in_range: bool = false

# Nodes and helpers
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var invul_timer: Timer = $Invultimer
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_box: Area2D = $AttackBox
@onready var fsm = $FiniteStateMachine

func _ready():
	add_to_group("enemy")  # Add to an enemy group if needed
	current_health = max_health

	# Connect attack box signals
	if attack_box:
		attack_box.connect("body_entered", Callable(self, "_on_attack_box_entered"))
		attack_box.connect("body_exited", Callable(self, "_on_attack_box_exited"))

	# Set up FSM references
	if fsm:
		fsm.actor = self  # Set this enemy as the FSM actor

	# Initialize invulnerability timer
	if invul_timer:
		invul_timer.wait_time = invul_duration
		invul_timer.one_shot = true
		invul_timer.connect("timeout", Callable(self, "_on_invul_timer_timeout"))

	# Set up detection area signals
	if detection_area:
		detection_area.connect("body_entered", Callable(self, "_on_detection_area_entered"))
		detection_area.connect("body_exited", Callable(self, "_on_detection_area_exited"))

func _physics_process(delta: float):
	# Confirm FSM processing and add debug to track
	if fsm:
		fsm._physics_process(delta)

	move_and_update_direction(delta)

func move_and_update_direction(delta: float):
	if current_direction != Vector2.ZERO:
		# Update `last_direction` and set velocity
		if abs(current_direction.x) > abs(current_direction.y):
			last_direction = Vector2.RIGHT if current_direction.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if current_direction.y > 0 else Vector2.UP

		velocity = current_direction * speed
		move_and_slide()

		# Play the appropriate animation if it’s not already playing
		match last_direction:
			Vector2.UP:
				if animator.current_animation != "walk_up":
					animator.play("walk_up")
			Vector2.DOWN:
				if animator.current_animation != "walk_down":
					animator.play("walk_down")
			Vector2.LEFT:
				if animator.current_animation != "walk_left":
					animator.play("walk_left")
			Vector2.RIGHT:
				if animator.current_animation != "walk_right":
					animator.play("walk_right")

func take_damage(amount: int):
	if is_dead or is_invulnerable:
		return  # Do nothing if already dead or invulnerable

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	print("Firey took damage:", amount, "- Current Health:", current_health)

	# Set invulnerability and start timer
	is_invulnerable = true
	if invul_timer:
		invul_timer.start()

	# If health is zero or below, handle death
	if current_health <= 0:
		is_dead = true
		emit_signal("defeated", self)  # Emit defeated signal
		if fsm and fsm.has_method("transition"):
			fsm.transition("DieState")
			animator.play("die_left")  # Play death animation
			_start_death_cleanup_timer()
	else:
		# Otherwise, transition to HurtState if still alive
		if fsm and fsm.has_method("transition"):
			fsm.transition("HurtState")

func is_player_in_range() -> bool:
	return player_in_range

func _start_death_cleanup_timer():
	var death_timer = Timer.new()
	death_timer.wait_time = 0.4
	death_timer.one_shot = true
	death_timer.connect("timeout", Callable(self, "_on_death_timer_timeout"))
	add_child(death_timer)  # Add timer as a child
	death_timer.start()

func _on_death_timer_timeout():
	print("Death timer completed. Queue freeing the Firey.")
	queue_free()  # Remove the Firey from the scene

func _on_invul_timer_timeout():
	is_invulnerable = false
	print("Firey is no longer invulnerable.")

func _on_detection_area_entered(body: Node):
	if body.is_in_group("player"):
		player_in_range = true
		player = body
		print("Player entered detection range.")

func _on_detection_area_exited(body: Node):
	if body.is_in_group("player"):
		player_in_range = false
		print("Player exited detection range.")

func _on_attack_box_entered(body: Node):
	if body.is_in_group("player"):
		player_in_attack_range = true
		fsm.transition("AttackState")
		print("Player entered attack range.")

func _on_attack_box_exited(body: Node):
	if body.is_in_group("player"):
		player_in_attack_range = false
		fsm.transition("RunState")
		print("Player exited attack range.")

func turn_to_player():
	if player:
		var direction_to_player = (player.global_position - global_position).normalized()
		if abs(direction_to_player.x) > abs(direction_to_player.y):
			last_direction = Vector2.RIGHT if direction_to_player.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if direction_to_player.y > 0 else Vector2.UP
		print("Wraith is now facing the player.")
