extends Node2D

@onready var overlay: ColorRect = $Overlay
@onready var slime_boss: Node = $SlimeBoss  
@onready var ui_manager: Node = $HealthUI
@onready var slime_boss_health_bar: ProgressBar = $HealthUI/BossHealthBar
@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")

func _ready():
	# Show transition effect
	overlay.visible = true
	var transition_instance = Scene_transition.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	var animation_player = transition_instance.get_node("AnimationPlayer")
	animation_player.play("fade_to_normal")
	overlay.visible = false

	# Wait for the transition to finish
	await animation_player.animation_finished

	# Handle boss room-specific logic
	if slime_boss and ui_manager:
		ui_manager.setup_boss_health(slime_boss)
	
	slime_boss_health_bar.visible = true

func setup_boss_health() -> void:
	# Notify the UI manager about the boss
	if ui_manager and slime_boss:
		ui_manager.connect_to_boss(slime_boss)

	# Connect defeat signal to handle post-boss logic using Callable
	slime_boss.connect("defeated", Callable(self, "_on_boss_defeated"))

func _on_boss_defeated() -> void:
	# Hide the boss health bar and perform additional cleanup if needed
	slime_boss_health_bar.visible = false
	print("Boss defeated! Handle any post-boss logic here.")
