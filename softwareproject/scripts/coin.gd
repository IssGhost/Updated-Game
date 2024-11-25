extends Node2D
class_name Coin

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area2d: Area2D = $Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area2d.connect("body_entered", Callable(self, "on_body_entered"))

func _on_body_entered(body:Node):
	if body.is_in_group("player"):
		print("player collided with the coin!")
		queue_free()
