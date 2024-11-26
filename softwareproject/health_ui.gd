extends CanvasLayer

# Player health configuration
@export var max_health: int = 10  # e.g., 5 hearts (2 health points per heart)
var current_health: int = max_health  # Start with full health

# Boss health configuration
@export var boss_max_health: int = 1000  # To be set when entering boss room
var boss_current_health: int = 1000

@onready var heart_scene = preload("res://Scenes/Heart.tscn")
@onready var health_container = $HealthContainer
@onready var boss_health_bar: ProgressBar = $BossHealthBar  # Reference to the boss health bar
@onready var player = preload("res://Scenes/player.tscn")  # Adjust as needed

func _ready():
	# Player health setup
	if player:
		player.connect("health_changed", Callable(self, "update_hearts"))
	else:
		print("Error: Player node not found. Check the path or ensure it is added to the scene before HealthUI.")

	# Hide boss health bar initially
	boss_health_bar.visible = true

	# Initial setup of hearts
	update_hearts()

# Function to handle player health updates
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

# Function to show and update boss health bar
func connect_to_boss(slime_boss: SlimeBoss) -> void:
	slime_boss.connect("health_changed", Callable(self, "_update_health_bar"))
	slime_boss.connect("defeated", Callable(self, "_hide_health_bar"))
	print("Connected to boss health_changed signal")
	boss_health_bar.max_value = slime_boss.max_hp
	boss_health_bar.value = slime_boss.max_hp
	boss_health_bar.visible = true

func _update_health_bar(new_health: int) -> void:
	boss_health_bar.value = new_health
	print("BossHealthBar max_value:", boss_health_bar.max_value)
	print("BossHealthBar value:", boss_health_bar.value)
func _hide_health_bar() -> void:
	boss_health_bar.visible = false


func _on_slimeboss_health_changed(new_health: Variant) -> void:
	print("Boss health updated to:", new_health)
	boss_health_bar.value = new_health
