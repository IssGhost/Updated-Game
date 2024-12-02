extends Area2D
class_name Projectile

@export var instant_vanish : bool = true
@export var is_exploding : bool = false
@export var speed : float
@export var max_speed : float
@export var acceleration : float
@export var current_damage : float
@export var lifetime : int = 180
@onready var detector : CollisionShape2D = $CollisionShape2D

var velocity : Vector2
var tick : int = 0

# Initializes the projectile with a direction and damage
func initialize(direction : Vector2, damage: float):
	velocity = direction.normalized() * max_speed  # Use normalized direction for consistent speed
	current_damage = damage  # Set the damage for this projectile

func _physics_process(delta):
	# Move the projectile
	position += velocity * delta
	
	# Handle projectile lifetime if it's an exploding type
	if is_exploding:
		tick += 1
		if tick >= lifetime:
			explode()
	
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(current_damage)  # Apply damage
		print("Projectile dealt ", current_damage, " damage to ", body)
		
	if is_exploding:
		explode()
		queue_free()
		
	if instant_vanish:
		queue_free()
	else:
		velocity = Vector2.ZERO
		set_physics_process(false)
		detector.set_deferred("disabled", true)
		var tw = create_tween().set_ease(Tween.EASE_IN_OUT)
		tw.finished.connect(_on_tween_finished)
		tw.tween_property(self, "modulate:a", 0.0, 0.1)

func _on_tween_finished():
	queue_free()
		
func explode():
	# Add explosion logic here (particles, sound, etc.)
	pass
