extends Node2D

@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var spawn_position: Node2D = $SpawnPosition 
@onready var area2d: Area2D = $StaticBody2D/Area2D

const ITEM_SCENE_PATH = "res://Scenes/heart_item.tscn"
const COINS_REQUIRED_TO_OPEN = 5

var is_open: bool = false  
var player_in_area: bool = false 

func _ready() -> void:
	area2d.body_entered.connect(_on_body_entered)
	area2d.body_exited.connect(_on_body_exited)
	animator.animation_finished.connect(_on_animation_finished)

func _process(_delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("select") and not is_open:
		if can_open_chest():
			open_chest()
		else:
			print("Not enough coins to open the chest.")

func can_open_chest() -> bool:
	return Globals.coin_count >= COINS_REQUIRED_TO_OPEN
	
func open_chest() -> void:
	Globals.coin_count -= COINS_REQUIRED_TO_OPEN  # Deduct coins
	print("Chest opened! Remaining coins:", Globals.coin_count)
	animator.play("open") 
	is_open = true  

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"): 
		player_in_area = true
		if is_open == false:
			animator.play("select")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"): 
		player_in_area = false
		if is_open == false:
			animator.play("default")

func _on_animation_finished(animation_name: String) -> void:
	if animation_name == "open":  
		spawn_item()

func spawn_item() -> void:
	var item_scene = load(ITEM_SCENE_PATH) as PackedScene 
	if item_scene:
		var item_instance = item_scene.instantiate()  
		item_instance.global_position = spawn_position.global_position
		get_parent().add_child(item_instance)
