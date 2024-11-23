extends State
class_name FireyAttackState

@export var attack_damage: int = 10
@export var fireball_scene = preload("res://Scenes/fireball.tscn")
@export var fire_interval: float = 1.0  # Interval between attacks
var attack_timer: Timer = null

func _ready():
	# Create and configure the attack timer
	if attack_timer == null:
		attack_timer = Timer.new()
		attack_timer.wait_time = fire_interval
		attack_timer.one_shot = false
		attack_timer.connect("timeout", Callable(self, "attack"))
		add_child(attack_timer)
		
func enter_state(_prev_state: State):
	print("Entering AttackState")
	if not attack_timer.is_connected("timeout", Callable(self, "attack")):
		attack_timer.connect("timeout", Callable(self, "attack"))
		print("Timer connected to attack method.")
	attack_timer.start()
	attack()
	print("Attack timer started with interval:", attack_timer.wait_time)


func _physics_process(delta: float):
	# Check if player is still in range
	if not actor.player_in_attack_range:
		if actor.player_in_range:
			print("Player moved out of attack range but still in detection range. Transitioning to FollowState.")
			transition.emit("FollowState")
		else:
			print("Player moved out of detection range. Transitioning to RunState.")
			transition.emit("RunState")
		return

	# Existing attack logic
	if actor.player:
		actor.turn_to_player()
	else:
		print("No player detected. Exiting AttackState.")
		transition.emit("RunState")


func attack():
	print("Attack method triggered.")
	if not actor.player or not actor.player_in_attack_range:
		print("Player out of attack range. Stopping attack.")
		exit_to_run_state()
		return

	print("Launching fireball at player!")
	var direction_to_player = (actor.player.global_position - actor.global_position).normalized()
	print("Fireball direction:", direction_to_player)
	print("Player position:", actor.player.global_position)
	print("Actor position:", actor.global_position)

	var fireball = fireball_scene.instantiate()
	fireball.global_position = actor.global_position

	if fireball.has_method("initialize"):
		print("Initializing fireball with direction and damage.")
		fireball.initialize(direction_to_player, attack_damage)
	else:
		print("Fireball has no initialize method.")

	# Ensure the fireball is added to the correct scene
	if actor.get_parent():
		actor.get_parent().add_child(fireball)
		print("Fireball added to the scene at:", fireball.global_position)
	else:
		print("Error: Actor has no parent to add fireball.")



func exit_to_run_state():
	# Cleanly exit the attack state
	if attack_timer:
		attack_timer.stop()
	transition.emit("RunState")

func exit_state():
	if attack_timer and attack_timer.is_connected("timeout", Callable(self, "attack")):
		attack_timer.stop()
		attack_timer.disconnect("timeout", Callable(self, "attack"))
	print("Exiting AttackState")
