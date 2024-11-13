extends Area2D

@export var speed: float = 800.0  # Velocity of the bullet
@export var attack_damage: int = 10  # Set the default damage for each bullet
var direction: Vector2 = Vector2.ZERO  # Direction the bullet will move
@onready var animated_sprite = $AnimatedSprite2D

func initialize(direction_vector: Vector2, damage: int):
	direction = direction_vector
	attack_damage = damage
	print("Direction set to:", direction, "Damage set to:", attack_damage)


func _ready():
	if animated_sprite:
		animated_sprite.play("default")
	else:
		print("AnimatedSprite2D not found in _ready")

func _process(delta):
	position += direction * speed * delta
	print("Fireball position:", position, " Direction:", direction)

	if is_outside_of_bounds():
		queue_free()
#func _on_body_entered(body):
	#if body.has_method("take_damage"):
		#body.take_damage(attack_damage)
	#queue_free()

func is_outside_of_bounds() -> bool:
	return position.x < 0 or position.x > get_viewport_rect().size.x or position.y < 0 or position.y > get_viewport_rect().size.y
