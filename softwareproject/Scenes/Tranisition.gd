extends Node2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func _ready():
	# Automatically start the dialogue as soon as the scene loads
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
	
func end_scene():
	get_tree().change_scene_to_file("res://Scenes/tile_map.tscn")
