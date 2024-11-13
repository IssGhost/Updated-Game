extends CanvasLayer

@export var max_health: int = 10  # e.g., 5 hearts (2 health points per heart)
var current_health: int = max_health  # Start with full health
@onready var heart_scene = preload("res://Scenes/Heart.tscn")
@onready var health_container = $HealthContainer
@onready var player = preload("res://Scenes/player.tscn")

func _ready():

	if player:
		player.connect("health_changed", Callable(self, "update_hearts"))
	else:
		print("Error: Player node not found. Check the path or ensure it is added to the scene before HealthUI.")

	# Initial setup of hearts
	update_hearts()

func update_hearts(new_health: int = current_health):
	current_health = new_health
	
	# Clear any existing hearts
	for child in health_container.get_children():
		child.queue_free()

	# Total number of hearts to display (each heart represents 2 health points)
	var heart_count = int(ceil(float(max_health) / 2))

	# Create hearts with correct visuals for each health point
	for i in range(heart_count):
		var heart = heart_scene.instantiate()
		heart.position = Vector2((i * 15) + 10, 10)
		health_container.add_child(heart)

		# Calculate the health state for this heart
		var health_for_this_heart = current_health - (i * 2)

		# Set the heart's animation based on the exact health value
		if health_for_this_heart >= 2:
			heart.play("Full")  # Full heart
		elif health_for_this_heart == 1:
			heart.play("Half")  # Half heart
		else:
			heart.play("Empty")  # Empty heart
