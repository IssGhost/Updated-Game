extends Node2D  # Attach this script directly to the "Spike" Node2D

# Array to store references to AnimatedSprite2D nodes
@onready var animated_sprites = []  # Array to store all AnimatedSprite2D nodes found

func _ready() -> void:
	print("Script attached to:", name)

	# Search for all Area2D children under this node (Spike)
	for child in get_children():
		if child is Area2D:
			child.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
			print("Connected signal for", child.name)
			
			# Find and store the AnimatedSprite2D within each Area2D
			if child.has_node("AnimatedSprite2D"):
				var animated_sprite = child.get_node("AnimatedSprite2D")
				animated_sprites.append(animated_sprite)
				print("Found AnimatedSprite2D for", child.name)
			else:
				print("No AnimatedSprite2D found in", child.name)

# Called when an Area2D child emits the `body_entered` signal
func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Signal triggered by:", body.name)
	if body.is_in_group("player"):
		# Iterate through Spike's children to find the Area2D that emitted the signal
		for child in get_children():
			if child is Area2D and child.has_node("AnimatedSprite2D"):
				# Check if the body is among the overlapping bodies
				var overlapping_bodies = child.get_overlapping_bodies()
				if overlapping_bodies.size() > 0 and overlapping_bodies.has(body):
					# Access the AnimatedSprite2D within the identified Area2D
					var animated_sprite = child.get_node("AnimatedSprite2D") as AnimatedSprite2D
					if animated_sprite:
						print("Playing animation for:", animated_sprite.name)
						animated_sprite.stop()  # Stop any currently playing animation
						animated_sprite.play("default")  # Start the "default" animation
					break  # Exit the loop once the correct Area2D is found
