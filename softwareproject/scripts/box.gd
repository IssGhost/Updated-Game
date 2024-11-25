extends Node2D
class_name Box

@onready var animated_sprite: AnimatedSprite2D = $StaticBody2D/AnimatedSprite2D
@onready var static_body_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var hurtbox_area: Area2D = $Hurtbox
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D

# Tracks whether the box is already destroyed
var is_destroyed: bool = false

func take_damage(damage: int) -> void:
	if is_destroyed:
		return  # Ignore if already destroyed

	print("Box took damage:", damage)
	destroy_box()

func destroy_box() -> void:
	if is_destroyed:
		return  # Ignore if already destroyed

	# Mark the box as destroyed
	is_destroyed = true

	# Play the destroyed animation
	animated_sprite.play("destroyed")

	# Disable the collision shapes
	static_body_collision.queue_free()
	print("Hurtbox CollisionShape2D disabled:", static_body_collision.disabled)

	hurtbox_collision.disabled = true
