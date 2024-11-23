extends Area2D

@export var speed: float = 100.0
@export var attack_damage: int = 10
var direction: Vector2 = Vector2.ZERO
@onready var animated_sprite = $AnimatedSprite2D

var velocity: Vector2
var damage: int

func initialize(direction: Vector2, dmg: int):
	velocity = direction.normalized() * speed  # Ensure the velocity is normalized
	damage = dmg
	print("Fireball initialized with direction:", direction, "and damage:", dmg)
	
	# Rotate the fireball to face the direction of travel
	rotation = direction.angle()

func _ready():
	if animated_sprite:
		animated_sprite.play("default")
	else:
		print("Error: AnimatedSprite2D not found!")

func _physics_process(delta: float):
	position += velocity * delta

	# Remove the fireball if it goes out of bounds
	if is_outside_of_bounds():
		print("Fireball out of bounds, removing.")
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
	queue_free()

func is_outside_of_bounds() -> bool:
	var viewport = get_viewport_rect()
	return position.x < 0 or position.y < 0 or position.x > viewport.size.x or position.y > viewport.size.y
