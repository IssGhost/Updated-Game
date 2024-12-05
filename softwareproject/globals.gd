extends Node

var coin_count: int = 0

@export var player_max_health: int = 100

@export var max_ammo: int = 50
var current_ammo: int = max_ammo

var player_current_health: int = player_max_health
var player_attack_damage: int = 100
var base_attack_damage: int = 100
var player_weapons: Array = ["default_gun"]
var current_weapon_index: int = 0
var player_current_wearpon: String = ""
var total_slime_health: int = 0

signal transition_to_boss_room
signal health_changed(new_health)
signal ammo_changed(current_ammo)
signal damage_changxed(new_damage)
signal max_health_changed(new_max_health)
signal total_slime_health_changed(new_total_health)  
signal current_weapon_UI()

func add_weapon(weapon_type: String) -> void:
	if not player_weapons.has(weapon_type):
		player_weapons.append(weapon_type)
		print("Weapon added to inventory:", weapon_type)

func swap_weapon():
	if player_weapons.size() > 1:
		current_weapon_index = (current_weapon_index + 1) % player_weapons.size()
		var new_weapon = player_weapons[current_weapon_index]
		print("Switched to weapon:", new_weapon)
		emit_signal("current_weapon_UI", new_weapon)
	else:
		print("Only one weapon available!")
		
func increase_max_health(amount: int) -> void:
	player_max_health += amount
	player_current_health += amount 
	emit_signal("max_health_changed", player_max_health)
	emit_signal("health_changed", player_current_health)  
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
	player_current_health -= amount
	player_current_health = clamp(player_current_health, 0, player_max_health)
	emit_signal("health_changed", player_current_health)

func heal(amount: int) -> void:
	player_current_health += amount
	player_current_health = clamp(player_current_health, 0, player_max_health)
	emit_signal("health_changed", player_current_health)

func reset_health():
	player_current_health = player_max_health
	emit_signal("health_changed", player_current_health)

func update_total_slime_health(amount: int) -> void:
	total_slime_health += amount
	total_slime_health = max(0, total_slime_health)
	emit_signal("total_slime_health_changed", total_slime_health)
	print("Total slime health updated to:", total_slime_health)
