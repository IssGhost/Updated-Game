extends Area2D

@export var speed: float = 800.0  # Velocity of the bullet
@export var attack_damage: int = 10  # Set the damage for each bullet
var direction: Vector2 = Vector2.ZERO  # Direction the bullet will move
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# Play the initial firing animation
	animated_sprite.play("start_gun")
	await animated_sprite.animation_finished  # Await the animation to finish
	# Transition to the looping animation
	animated_sprite.play("final_gun")

func _process(delta):
	# Move the bullet in the specified direction
	position += direction * speed * delta

	# Remove the bullet if it goes off-screen or any other boundary condition you set
	if is_outside_of_bounds():
		queue_free()

# Called when the bullet collides with another body
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)  # Pass attack_damage as the argument
		queue_free()  # Destroy the bullet on impact

func is_outside_of_bounds() -> bool:
	# Large bounds to ensure bullets are not prematurely removed
	var visible_rect = Rect2(-10000, -10000, 20000, 20000)  # Huge bounds
	return not visible_rect.has_point(global_position)
