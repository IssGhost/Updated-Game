extends Node2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "intro_dialogue"
@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")

const Balloon = preload("res://Dialogue/balloon.tscn")
var is_finished

func _ready():
	var balloon: Node = Balloon.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource, dialogue_start)
	
	
func end_scene():
	var transition_instance = Scene_transition.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animation_player = transition_instance.get_node("AnimationPlayer")
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://Scenes/tile_map.tscn")
