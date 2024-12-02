extends Area2D
class_name Destructable

@export var target: Node2D  # Should point to the Box node
@export var damage: int = 1  # Default damage dealt when hit

func _on_area_entered(area: Area2D):
	# Debug print to check when this function is called
	print("Area entered: ", area.name)

	# Check if the area is the player's AttackBox
	if area.name == "AttackBox":
		print("AttackBox detected!")

		# Pass the damage to the target (Box)
		if target and target.has_method("take_damage"):
			target.take_damage(damage)
		else:
			print("Error: Target does not have a take_damage method!")
