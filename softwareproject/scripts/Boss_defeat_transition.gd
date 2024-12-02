extends Node2D

@export var next_scene: String = "res://Scenes/tile_map.tscn"  # Path to the next scene
@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")

@onready var transition_sprite: Sprite2D = $Sprite2D  # The Sprite2D child for visual representation
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

@onready var area: Area2D = $Area2D
func _ready():
	transition_sprite.visible = false
	collision_shape.disabled = true
	
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("player entered the area2d")
		_transition_to_next_scene()
	else:
		print("Something other than the player entered Area2D:", body.name)
		
func _transition_to_next_scene() -> void:
	# Instantiate and play the transition animation
	var transition_instance = Scene_transition.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animation_player = transition_instance.get_node("AnimationPlayer")
	animation_player.play("fade_to_black")
	await animation_player.animation_finished

	# Change to the next scene
	get_tree().change_scene_to_file("res://Scenes/tile_map.tscn")


func _on_slimeboss_defeated() -> void:
	transition_sprite.visible = true
	collision_shape.set_deferred("disabled", false)
	print("Boss defeated! Area2D activated.")
