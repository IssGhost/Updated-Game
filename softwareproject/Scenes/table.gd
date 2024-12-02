extends Node2D

@onready var area2d: Area2D = $StaticBody2D/Area2D
@onready var animator: AnimationPlayer = $AnimationPlayer

var player_in_area: bool = false
var is_flipped: bool = false 
var player_position: Vector2 = Vector2.ZERO  

func _ready() -> void:
	area2d.body_entered.connect(_on_Area2D_body_entered)
	area2d.body_exited.connect(_on_Area2D_body_exited)

func _process(_delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("select") and not is_flipped:
		_flip_table()

func _on_Area2D_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  
		print("Player entered area2d")
		player_in_area = true
		player_position = body.global_position  
		if not is_flipped:  
			animator.play("select")

func _on_Area2D_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"): 
		player_in_area = false
		if not is_flipped: 
			animator.play("default")

# Flip table logic
func _flip_table() -> void:
	var table_position = global_position
	if player_position.y < table_position.y:  
		animator.play("fliptop")
	else:  
		animator.play("flipbot")
	is_flipped = true 
