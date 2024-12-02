extends Node2D  # The root node of the door scene

@onready var animated_sprite = $Area2D/AnimationPlayer
@onready var left_collision = $Area2D/StaticBody2D/Top
@onready var right_collision = $Area2D/StaticBody2D/Bottom
@onready var sound_effect = $Area2D/AudioStreamPlayer2D

var is_locked = false

func _ready():
	# Connect to the global lock and unlock signals emitted by the main scene
	get_parent().connect("lock_doors", Callable(self, "lock"))
	get_parent().connect("unlock_doors", Callable(self, "unlock"))
	
func lock():
	is_locked = true
	left_collision.set_disabled(false)
	right_collision.set_disabled(false)

	print("Door locked")

func unlock():
	is_locked = false
	left_collision.set_disabled(true)
	right_collision.set_disabled(true)
	print("Door unlocked by signal")




# Function triggered when the player enters the door's detection area
func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		if is_locked == true:
			print("The door is locked. Defeat all enemies to unlock.")
			return
		if is_locked == false:
			animated_sprite.play("Open")
		# Play the unlock animation and sound
		if not animated_sprite.is_playing():
			animated_sprite.play("Open")
			sound_effect.play()


func _on_Area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not is_locked:  # Only play the close animation if the door is unlocked
			animated_sprite.play("Close")
			sound_effect.play()
			print("Door closing after player exits area.")
