extends Node2D
@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")


func _ready():
	var transition_instance = Scene_transition.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animation_player = transition_instance.get_node("AnimationPlayer")
	animation_player.play("fade_to_normal")
	
	await animation_player.animation_finished
	
