extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@export var heal_amount: int = 20
var player_in_area: bool = false
var is_picked_up: bool = false

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_area and not is_picked_up:
		_pick_up_item()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  
		player_in_area = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):  
		player_in_area = false


func _pick_up_item() -> void:
	if not is_picked_up:
		is_picked_up = true  
		if Globals.player_current_health == Globals.player_max_health:
			Globals.increase_max_health(20)
		else:
			Globals.heal(heal_amount)
		queue_free()
