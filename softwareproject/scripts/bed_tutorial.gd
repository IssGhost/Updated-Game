extends Node2D

@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")

@onready var collision_shape: CollisionShape2D = $Bed/Area2D/CollisionShape2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and Input.is_action_just_pressed("dialogue"):
		print("player entered the area2d")
		_transition_to_next_scene()

func _transition_to_next_scene() -> void:
	# Instantiate and play the transition animation
	var transition_instance = Scene_transition.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animation_player = transition_instance.get_node("AnimationPlayer")
	animation_player.play("fade_to_black")
	await animation_player.animation_finished

	# Change to the next scene
	get_tree().change_scene_to_file("res://Scenes/StartScreen.tscn")
