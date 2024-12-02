extends Node2D  # The root node of the door scene

@onready var animated_sprite = $Area2D/AnimationPlayer
@onready var top_collision = $Area2D/StaticBody2D/left
@onready var bottom_collision = $Area2D/StaticBody2D/right
@onready var sound_effect = $Area2D/AudioStreamPlayer2D

var is_locked = false

func _ready():
	# Connect to the global lock and unlock signals emitted by the main scene
	get_parent().connect("lock_doors", Callable(self, "lock"))
	get_parent().connect("unlock_doors", Callable(self, "unlock"))
	
func lock():
	is_locked = true
	top_collision.set_disabled(false)
	bottom_collision.set_disabled(false)
	#animated_sprite.play("Close")
	#sound_effect.play()
	print("Door locked")

func unlock():
	is_locked = false
	top_collision.set_disabled(true)
	bottom_collision.set_disabled(true)
	#animated_sprite.play("Open")
	#sound_effect.play()
	print("Door unlocked")



# Function triggered when the player enters the door's detection area
func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		if is_locked:
			print("The door is locked. Defeat all enemies to unlock.")
			return

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
