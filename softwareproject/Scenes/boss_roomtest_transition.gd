extends Node2D
@onready var overlay: ColorRect = $Overlay
@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")

@onready var health_bar = $BossHealthBar/ProgressBar
@onready var slime_boss = $SlimeBoss


func _ready():
	#Scene Transition logic
	overlay.visible = true
	var transition_instance = Scene_transition.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animation_player = transition_instance.get_node("AnimationPlayer")
	animation_player.play("fade_to_normal")
	
	overlay.visible = false
	await animation_player.animation_finished
	
	
	#Slimeboss logic
	slime_boss.connect("health_changed", Callable(self, "_update_health_bar"))
	_update_health_bar(slime_boss.current_health)
	
func _update_health_bar(new_health):
	health_bar = new_health
	
