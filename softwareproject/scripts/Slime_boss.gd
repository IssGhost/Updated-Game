extends CharacterBody2D
class_name SlimeBoss

# Signals
signal health_changed(new_health)
signal defeated

# Configurable variables
@export var max_hp: int = 1000
@export var jump_force: float = 20
@export var acceleration: float = 30
@export var max_speed: float = 40
@export var friction: float = 0.15
@export var hurt_duration: float = 0.1
@export var hit_effect_scene: PackedScene = preload("res://Characters/Bosses/HitEffect.tscn")

# References
@onready var fsm: Node = $FSM
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hurt_timer: Timer = $HurtTimer
@onready var player: CharacterBody2D = get_tree().current_scene.get_node("player")
@onready var hurtbox: Area2D = $Hitbox
@onready var connecrtions: Array

# Internal variables
var mov_direction: Vector2 = Vector2.ZERO
var hp: int = max_hp
var is_hurt: bool = false
var split_thresholds: Array = [500, 250]  # Add split thresholds here

var damage: int = 10

@export var attack_damage = 10 # New slime scene (representing smaller slimes)
@export var slime_scene: PackedScene = preload("res://Scenes/Slime_Boss.tscn")

func _ready() -> void:
	hurtbox.connect("body_entered", Callable(self, "_on_hurtbox_body_entered"))
	if player == null:
		print("Error: Player not found!")
	else:
		print("Player initialized at position:", player.global_position)

	if fsm:
		fsm.set_state(fsm.states.idle)
	else:
		print("Error: FSM not found!")

	if navigation_agent.get_navigation_map() == null:
		print("Error: NavigationRegion2D not connected!")
	else:
		print("Navigation map initialized.")

	hurt_timer.wait_time = hurt_duration
	hurt_timer.one_shot = true
	hurt_timer.connect("timeout", Callable(self, "_on_hurt_timer_timeout"))
	var defeated_connections = self.defeated.get_connections()
	for connection in defeated_connections:
		print("Signal: ", connection.signal)
		print("Callable: ", connection.callable)
		print("Flags: ", connection.flags)

func _physics_process(delta: float) -> void:
	move_and_slide()
	velocity = lerp(velocity, Vector2.ZERO, friction)
	if fsm:
		fsm._physics_process(delta)

func chase() -> void:
	navigation_agent.target_position = player.global_position
	if !navigation_agent.is_target_reached():
		var vector_to_next_point: Vector2 = navigation_agent.get_next_path_position() - global_position
		mov_direction = vector_to_next_point.normalized() * max_speed

		if vector_to_next_point.x > 0:
			sprite.flip_h = false
		elif vector_to_next_point.x < 0:
			sprite.flip_h = true

func _on_hurtbox_body_entered(area: Node):
	print("Collision detected with:", area)  # Debug line

	if area.has_method("get_damage_amount"):
		var damage = area.get_damage_amount()
		print("boss took damage")
		take_damage(damage)
	else:
		print("no damage found")

func get_damage_amount() -> int:
	return 20  # Replace with the actual damage amount for the boss

func take_damage(amount: int) -> void:
	print("Taking damage:", amount, " | is_hurt:", is_hurt, " | hp:", hp)  # Debug line

	if is_hurt or hp <= 0:
		return

	var previous_hp = hp
	hp -= amount
	print(previous_hp)
	emit_signal("health_changed", hp)

	for threshold in split_thresholds:
		if previous_hp > threshold and self.hp <= threshold:
			split()
			split_thresholds.erase(threshold)  # Remove only the matching threshold
			break  # Exit loop after handling the split

	if hp > 0:
		is_hurt = true
		hurt_timer.start()
		sprite.play("hurt")
		fsm.set_state(fsm.states.hurt)
	else:
		emit_signal("defeated")
		fsm.set_state(fsm.states.dead)
		sprite.play("dead_explosion")  # Play death animation
		
		# Add a timer to delay removal
		var death_timer = Timer.new()
		death_timer.wait_time = 1.0  # Adjust time as needed
		death_timer.one_shot = true
		add_child(death_timer)
		death_timer.connect("timeout", Callable(self, "_on_death_timer_timeout"))
		death_timer.start()

func split() -> void:
	# Create two smaller slimes
	for i in range(2):
		var new_slime = slime_scene.instantiate()
		new_slime.global_position = self.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		new_slime.max_hp = hp  # Pass reduced health to the new slimes
		new_slime.hp = hp
		get_tree().current_scene.add_child(new_slime)

	print("SlimeBoss split into two smaller slimes!")

func _on_death_timer_timeout() -> void:
	queue_free()


func _on_hurt_timer_timeout() -> void:
	is_hurt = false
	fsm.set_state(fsm.states.idle)

func _spawn_hit_effect() -> void:
	var hit_effect = hit_effect_scene.instantiate()
	add_child(hit_effect)


func _on_attack_box_body_entered(body):
	print("body_entered signal triggered with:", body.name)  # Debug
	if body.has_method("take_damage") and body.is_in_group("player"):
		body.take_damage(damage)
		print("Dealt", damage, "damage to", body.name)

func _on_attack_box_area_entered(area):
	print("area_entered signal triggered with:", area.name)  # Debug
	if area.has_method("take_damage") and area.is_in_group("player"):
		area.take_damage(damage)
		print("Dealt", damage, "damage to", area.name)
