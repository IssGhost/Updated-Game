extends Enemy

@export var max_health: int = 100
var current_health: int

signal health_changed(new_health)

@export var jump_force: float = 300  # Adjust as necessary


func _ready():
	current_health = max_health
	
	
func _process(_delta: float) -> void:
	if is_instance_valid(player):
		if player.global_position.y > global_position.y:
			z_index = 0
		else:
			z_index = 1

	# Use the built-in velocity in CharacterBody2D and move with move_and_slide
	move_and_slide()



func duplicate_slime() -> void:
	if scale > Vector2(1, 1):
		var impulse_direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0, 2*PI))
		_spawn_slime(impulse_direction)
		_spawn_slime(impulse_direction * -1)


func _spawn_slime(direction: Vector2) -> void:
	var slime: CharacterBody2D = load("res://Characters/Enemies/Bosses/SlimeBoss.tscn").instantiate()
	slime.position = position
	slime.scale = scale/2
