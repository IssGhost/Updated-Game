extends Node


# Configuration
@export var damage_increase: int = 10  # Amount to increase the player's damage
@export var duration: float = 15.0  # Duration for the damage increase
@onready var timer: Timer = $Timer  # Reference to the Timer node
@onready var player: CharacterBody2D = $TileMap/player
@onready var dmg_up_label: Label = $TileMap/player/Damageup  # Path to "DMG UP" label on the player
@onready var anim: AnimationPlayer = $AnimationPlayer
var is_on_cooldown: bool = false  # Tracks if the item is on cooldown

func find_node_endswith(target: String) -> Node:
	for node in get_tree().get_root().get_children():
		if node.name.ends_with(target):
			return node
	return null
	
func _ready():
	# Ensure the label is initially hidden
	if dmg_up_label:
		dmg_up_label.visible = false

	# Connect the Timer timeout signal
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))

func _input(event: InputEvent) -> void:
	# Check if the "usable" action is triggered and the item is not on cooldown
	if event.is_action_pressed("usable") and not is_on_cooldown:
		activate_item()

func activate_item() -> void:
	# Ensure the item is not on cooldown
	if is_on_cooldown:
		return

	# Increase the player's damage globally
	Globals.increase_damage(damage_increase, duration)

	# Show the "DMG UP" label
	_show_dmg_up_label()

	# Start the cooldown
	is_on_cooldown = true
	timer.start()  # Start the cooldown timer
	anim.play("Used")
	
func _show_dmg_up_label() -> void:
	if dmg_up_label:
		dmg_up_label.visible = true
		# Hide the label after 1 second
		get_tree().create_timer(15.0).timeout.connect(Callable(self, "_hide_dmg_up_label"))

func _hide_dmg_up_label() -> void:
	if dmg_up_label:
		dmg_up_label.visible = false

func _on_timer_timeout() -> void:
	# Reset cooldown state
	is_on_cooldown = false
