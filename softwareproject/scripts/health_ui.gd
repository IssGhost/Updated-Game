extends CanvasLayer

@export var max_health: int = 10  # 3 full hearts (2 health points per heart)
var current_health: int = max_health  # Start with full health
@onready var heart_scene = preload("res://Heart.tscn")  # Path to the Heart scene
@onready var health_container = $HealthContainer  # Reference to the HBoxContainer

func _ready():
	update_hearts()  # Initialize with full hearts

func update_hearts():
	# Clear any existing hearts in the health_container
	for child in health_container.get_children():
		child.queue_free()

	# Calculate the number of hearts we need to display
	var heart_count = int(max_health / 2)

	# Loop to create each heart and set its animation with position offset
	for i in range(heart_count):
		var heart = heart_scene.instantiate()
		heart.position = Vector2((i * 15)+ 10 , 10)  # Offset each heart by 50 pixels on the x-axis
		health_container.add_child(heart)

		# Set the correct animation based on current health
		if current_health >= (i + 1) * 2:
			heart.play("Full")  # Full heart
		elif current_health == (i * 2) + 1:
			heart.play("Half")  # Half heart
		else:
			heart.play("Empty")  # Empty heart

func decrease_health(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)
	update_hearts()

# Function to increase health and update the UI
func increase_health(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	update_hearts()
