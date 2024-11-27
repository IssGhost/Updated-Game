extends Node2D

@onready var slime_boss_health_bar: ProgressBar = $Control/BossHealthBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slime_boss_health_bar.visible = false
