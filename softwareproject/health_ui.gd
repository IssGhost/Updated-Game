extends CanvasLayer

# Player health configuration
@export var max_health: int = 100  # e.g., 5 hearts (2 health points per heart)
var current_health: int = max_health  # Start with full health

# Boss health configuration
@export var boss_max_health: int = 1000  # To be set when entering boss room
var boss_current_health: int = 1000

@onready var weapon_sprite: AnimatedSprite2D = $Weapon/AnimatedSprite2D
@onready var flamethrower_animation: String = "flamethrower" 
@onready var heart_scene = preload("res://Scenes/Heart.tscn")
@onready var health_container = $HealthContainer
@onready var boss_health_bar: ProgressBar = $BossHealthBar  # Reference to the boss health bar
@onready var player = preload("res://Scenes/player.tscn")  # Adjust as needed
@onready var ammo_label: RichTextLabel = $Weapon/RichTextLabel # Adjust path as needed
@onready var damageboost: Sprite2D = $Control/Sprite2D
func _ready():
	Globals.connect("current_weapon_UI", Callable(self, "_on_weapon_changed"))
	Globals.connect("health_changed", Callable(self, "update_hearts"))
	Globals.connect("max_health_changed", Callable(self, "update_hearts"))  # Update when max health changes
	update_hearts(Globals.player_current_health)  # Initialize with the current global health
	
	Globals.connect("ammo_changed", Callable(self, "update_ammo_label"))
	update_ammo_label(Globals.current_ammo)  # Initialize the ammo label

	# Hide boss health bar initially
	boss_health_bar.visible = false
	
func _on_weapon_changed(new_weapon: String) -> void:
	print("Weapon changes to test:", new_weapon)
	if new_weapon == "flamethrower":
		play_flamethrower_animation()
	if new_weapon == "default_gun":
		weapon_sprite.play("default")

func play_flamethrower_animation() -> void:
	if weapon_sprite.animation != flamethrower_animation:
		weapon_sprite.play(flamethrower_animation)
		print("playing flamethrower animation")
	else:
		print("flamethower animation already player")
func update_ammo_label(current_ammo: int) -> void:
	ammo_label.text = str(current_ammo) + "/" + str(Globals.max_ammo)
	
# Function to handle player health updates
func update_hearts(new_health: int):
	# Update global variables to reflect the current state
	Globals.player_current_health = new_health
	current_health = new_health

	# Clear any existing hearts in the health container
	for child in health_container.get_children():
		child.queue_free()

	# Dynamically calculate the total number of hearts based on Globals.player_max_health
	var heart_count = int(ceil(float(Globals.player_max_health) / 20))

	# Create the correct number of heart visuals
	for i in range(heart_count):
		var heart = heart_scene.instantiate()
		heart.position = Vector2((i * 15) + 10, 10)  # Adjust position spacing as needed
		health_container.add_child(heart)

		# Calculate the health for the current heart (each heart represents 20 HP)
		var health_for_this_heart = new_health - (i * 20)

		# Update the heart's animation based on its state
		if health_for_this_heart >= 20:
			heart.play("Full")  # Full heart
		elif health_for_this_heart > 0:
			heart.play("Half")  # Half heart
		else:
			heart.play("Empty")  # Empty heart

# Function to show and update boss health bar
func connect_to_boss(slime_boss: SlimeBoss) -> void:
	slime_boss.connect("health_changed", Callable(self, "_update_health_bar"))
	print("Connected slime_boss health_changed signal to _update_boss_health.")

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


func _on_boss_defeated() -> void:
	pass # Replace with function body.
