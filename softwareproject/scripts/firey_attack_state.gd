extends State
class_name FireyAttackState

@export var attack_damage: int = 10
@export var fireball_scene = preload("res://Scenes/fireball.tscn")  # Ensure this path is correct
@export var fire_interval: float = 1.0  # Interval between each fireball
var attack_timer: Timer = null  # Declare the timer variable

func _ready():
	# Initialize the attack_timer once
	attack_timer = Timer.new()
	attack_timer.wait_time = fire_interval
	attack_timer.one_shot = false
	attack_timer.connect("timeout", Callable(self, "attack"))
	add_child(attack_timer)  # Add the timer to the scenefunc enter_state(_prev_state: State):
	print("Entering AttackState - Preparing to attack")


	# Set up attack timer for repeated firing
	attack_timer = Timer.new()
	attack_timer.wait_time = 1.0
	attack_timer.one_shot = false
	add_child(attack_timer)

	# Connect the attack timer's timeout signal to call the attack function if not connected
	if not attack_timer.is_connected("timeout", Callable(self, "attack")):
		attack_timer.connect("timeout", Callable(self, "attack"))

	# Start the attack timer
	attack_timer.start()

func attack():
	# Check if player is in attack range before firing
	if not actor.player_in_attack_range:
		print("Player moved out of attack range, transitioning to RunState.")
		transition.emit("RunState")
		attack_timer.stop()
		return

	# Fireball creation logic if player is in range
	var direction_to_player = (actor.player.global_position - actor.global_position).normalized()
	var fireball = fireball_scene.instantiate()
	fireball.global_position = actor.global_position

	if fireball.has_method("initialize"):
		fireball.initialize(direction_to_player, attack_damage)
	
	actor.get_parent().add_child(fireball)
	print("Fireball launched toward player")

func exit_state():
	# Clean up attack timer when exiting AttackState
	if attack_timer.is_connected("timeout", Callable(self, "attack")):
		attack_timer.stop()
		attack_timer.disconnect("timeout", Callable(self, "attack"))
	attack_timer.queue_free()
	print("Exiting AttackState")
