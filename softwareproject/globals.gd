extends Node

var is_finished: String = ""
var coin_count: int = 0

@export var player_max_health: int = 100

@export var max_ammo: int = 50
var current_ammo: int = max_ammo

var player_current_health: int = player_max_health
var player_attack_damage: int = 100
var base_attack_damage: int = 100

signal transition_to_boss_room
signal health_changed(new_health)
signal ammo_changed(current_ammo)
signal damage_changed(new_damage)
signal max_health_changed(new_max_health)

func increase_max_health(amount: int) -> void:
	player_max_health += amount
	player_current_health += amount  # Heal to match the new max health
	emit_signal("max_health_changed", player_max_health)
	emit_signal("health_changed", player_current_health)  # Update health too
	print("Max health increased to:", player_max_health)
	
func increase_damage(amount: int, duration: float) -> void:
	base_attack_damage = player_attack_damage
	player_attack_damage += amount 
	print("Damage increased to:", player_attack_damage)
	

	get_tree().create_timer(duration).connect("timeout", Callable(self, "reset_damage"))

func reset_damage() -> void:
	player_attack_damage = base_attack_damage 
	print("Damage reverted to:", player_attack_damage)
	
func decrement_ammo() -> void:
	if current_ammo > 0:
		current_ammo -= 1
		emit_signal("ammo_changed", current_ammo)

func reload_ammo():
	current_ammo = max_ammo
	emit_signal("ammo_changed", current_ammo)

func reload():
	reload_ammo()
	
func add_coin():
	coin_count += 1
	print("Coins collected:", coin_count)

func deduct_coin(amount: int):
	coin_count -= amount
	coin_count = max(coin_count, 0) 
	print("Coins deducted. Remaining coins:", coin_count)
	
func reset_coins():
	coin_count = 0

func take_damage(amount: int) -> void:
	# Reduce health and emit signal
	player_current_health -= amount
	player_current_health = clamp(player_current_health, 0, player_max_health)
	emit_signal("health_changed", player_current_health)

func heal(amount: int) -> void:
	# Heal player and emit signal
	player_current_health += amount
	player_current_health = clamp(player_current_health, 0, player_max_health)
	emit_signal("health_changed", player_current_health)

func reset_health():
	# Reset health to maximum
	player_current_health = player_max_health
	emit_signal("health_changed", player_current_health)
