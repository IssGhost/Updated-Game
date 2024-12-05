extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Flags to track player presence and pickup state
var player_in_area: bool = false
var is_picked_up: bool = false

@export var weapon_type: String = "default_gun"
func _ready() -> void:
	# Connect Area2D signals
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Check if the player presses the select input and is in the area
	if player_in_area and Input.is_action_just_pressed("select") and not is_picked_up:
		_pick_up_item()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):  # Ensure it's the player entering
		player_in_area = true
		if animated_sprite.animation != "select":
			animated_sprite.play("select")  # Play the "select" animation

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):  # Ensure it's the player exiting
		player_in_area = false
		if not is_picked_up:
			animated_sprite.play("default")  # Reset to the "default" animation

func _pick_up_item() -> void:
	is_picked_up = true  # Mark the item as picked up
	print("picked up:", weapon_type)
	
	if Globals.has_method("add_weapon"):
		Globals.add_weapon(weapon_type)
		
	animated_sprite.play("pickup")  # Optional: Play a pickup animation
	queue_free()  # Remove the item from the scene
