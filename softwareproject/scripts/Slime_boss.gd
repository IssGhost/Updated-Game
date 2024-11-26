extends CharacterBody2D
class_name SlimeBoss

# Signals
signal health_changed(new_health)
signal defeated

# Configurable variables
@export var max_hp: int = 1000
@export var jump_force: float = 100
@export var acceleration: float = 40
@export var max_speed: float = 100
@export var friction: float = 0.15
@export var hurt_duration: float = 0.5
@export var hit_effect_scene: PackedScene = preload("res://Characters/Bosses/HitEffect.tscn")

# References
@onready var fsm: Node = $FSM
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hurt_timer: Timer = $HurtTimer
@onready var player: CharacterBody2D = get_tree().current_scene.get_node("player")
@onready var hurtbox: Area2D = $Hitbox

# Internal variables
var mov_direction: Vector2 = Vector2.ZERO
var hp: int = max_hp
var is_hurt: bool = false

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
	if area.has_method("get_damage_amount"):
		var damage = area.get_damage_amount()
		print("boss took damage")
		take_damage(damage)
	else:
		print("no damage found")

func get_damage_amount() -> int:
	return 20  # Replace with the actual damage amount for the boss

func take_damage(amount: int) -> void:
	if is_hurt or hp <= 0:
		return

	hp -= amount
	emit_signal("health_changed", hp)

	if hp > 0:
		is_hurt = true
		hurt_timer.start()
		sprite.play("hurt")
		fsm.set_state(fsm.states.hurt)
	else:
		emit_signal("defeated")
		fsm.set_state(fsm.states.dead)
		sprite.play("death")  # Play death animation
		
		# Add a timer to delay removal
		var death_timer = Timer.new()
		death_timer.wait_time = 1.0  # Adjust time as needed
		death_timer.one_shot = true
		add_child(death_timer)
		death_timer.connect("timeout", Callable(self, "_on_death_timer_timeout"))
		death_timer.start()

func _on_death_timer_timeout() -> void:
	queue_free()


func _on_hurt_timer_timeout() -> void:
	is_hurt = false
	fsm.set_state(fsm.states.idle)

func _spawn_hit_effect() -> void:
	var hit_effect = hit_effect_scene.instantiate()
	add_child(hit_effect)
