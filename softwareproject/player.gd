extends CharacterBody2D

signal health_changed(new_health)  # Signal to notify health changes

@onready var dmg_up_label: Label = $Damageup
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var gunanim: AnimationTree = $Node2D/ArGun/AnimationTree
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_box: Area2D = $AttackBox
@onready var hurt_box: Area2D = $Hurtbox
@onready var sound_effect = $AudioStreamPlayer2D
@export var speed = 100
@export var attack_damage = 100
@export var max_health: int = 100
@export var dodge_duration: float = 1.0
@export var dodge_speed_multiplier: float = 2.0
@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var gun = $Node2D/ArGun
@onready var ar_gun: PackedScene = preload("res://Weapons/ar_gun.tscn")
@onready var flamethrower_gun: PackedScene = preload("res://Weapons/flamethrower_gun.tscn")
@export var gun_fire_scene: PackedScene = preload("res://Scenes/gun_fire.tscn")
@onready var reload_label: Label = $Reload
@onready var reload_timer: Timer = $ReloadTimer
@export var reload_duration: float = 1.0  
@onready var health_ui: Node = get_tree().current_scene.get_node("HealthUI") 
@onready var shoot_timer: Timer = $ShootTimer  
@export var shoot_interval: float = 0.2 
@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")
@export var current_weapon: String = ""


var current_ammo: int = Globals.current_ammo  # Track ammo locally
var max_ammo: int = Globals.max_ammo  # Max ammo capacity


var current_dir = "none"
var is_attacking = false
var is_hurt = false
var is_dodging: bool = false
var current_health: int = max_health

func _ready():
	anim.play("front_idle")
	attack_box.connect("body_entered", Callable(self, "_on_attack_box_body_entered"))
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))
	add_to_group("player")
	reset_state()
	
	reload_timer.wait_time = reload_duration
	reload_timer.one_shot = true
	reload_timer.connect("timeout", Callable(self, "_on_reload_finished"))
	shoot_timer.wait_time = shoot_interval
	shoot_timer.one_shot = false
	shoot_timer.connect("timeout", Callable(self, "_on_shoot_timer_timeout"))
	# Hide reload label initially
	reload_label.visible = false
	
	attack_damage = Globals.player_attack_damage

func reset_state():
	is_attacking = false
	is_hurt = false

func _physics_process(delta):
	if not is_attacking and not is_hurt:
		player_movement(delta)
	
	attack_damage = Globals.player_attack_damage


var gamestart_initial_direction = false


func _show_dmg_up_label() -> void:
	dmg_up_label.visible = true
	await get_tree().create_timer(15.0).timeout  # Show for 1 second
	dmg_up_label.visible = false
	
func collect_coin():
	Globals.add_coin() 

func player_movement(delta):
	if gamestart_initial_direction == false:
		current_dir = "down"
		gamestart_initial_direction = true

	# Handle directional input
	if Input.is_action_pressed("ui_right"):
		current_dir = "right"
		velocity = Vector2(speed, 0)
	elif Input.is_action_pressed("ui_left"):
		current_dir = "left"
		velocity = Vector2(-speed, 0)
	elif Input.is_action_pressed("ui_down"):
		current_dir = "down"
		velocity = Vector2(0, speed)
	elif Input.is_action_pressed("ui_up"):
		current_dir = "up"
		velocity = Vector2(0, -speed)
	else:
		velocity = Vector2.ZERO

	# Adjust animations based on movement state
	if velocity != Vector2.ZERO:
		play_movement_animation()
	else:
		play_idle_animation()

	move_and_slide()



func play_movement_animation():
	if is_attacking or is_hurt:
		return
	match current_dir:
		"right":
			sprite.flip_h = false
			anim.play("right_walk")
		"left":
			anim.play("left_walk")
		"down":
			anim.play("front_walk")
		"up":
			anim.play("back_walk")

func play_idle_animation():
	if is_attacking or is_hurt or is_dodging:
		return
	match current_dir:
		"right":
			anim.play("right_idle")
		"left":
			anim.play("left_idle")
		"down":
			anim.play("front_idle")
		"up":
			anim.play("back_idle")

func _input(event):
	if event.is_action_pressed("attack"):
		attack()
	if event.is_action_pressed("shoot") and shoot_timer.is_stopped():
		shoot_gun()
		shoot_timer.start()
	elif event.is_action_released("shoot"):
		shoot_timer.stop()
	if event.is_action_pressed("dodge") and not is_dodging:  # Add dodge input
		start_dodge()
	if event.is_action_pressed("reload"):  # Define "reload" in your Input Map
		start_reloading()
		Globals.reload()
	if event.is_action_pressed("swap_weapon"):
		Globals.swap_weapon()

func _on_shoot_timer_timeout():
	shoot_gun()
	
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("dialogue"):
		print("dialouge")
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			print("dialouge working")

			actionables[0].action()
			return
	if Input.is_action_just_pressed("selectable"):  # Ensure "selectable" is mapped to "E" in Input Map
		var actionables = actionable_finder.get_overlapping_areas()  # Get areas overlapping with the player's finder
		for area in actionables:
			if area.collision_layer == 16:  # Check if the object is in the selectable layer
				print("Interacting with selectable object!")
				area.action()  # Call a custom action method on the object, if it exists
			
func start_dodge():
	if is_dodging:
		return

	is_dodging = true
	#self.modulate = Color(0, 0, 0, 0.5)  # Set to shadow-like appearance
	hurt_box.set("disabled", true)  # Disable hurtbox collision
	speed *= dodge_speed_multiplier  # Temporarily increase speed
	anim.stop()
	match current_dir:
		"right":
			anim.play("right_dodge")
		"left":
			anim.play("left_dodge")
		"down":
			anim.play("front_dodge")
		"up":
			anim.play("back_dodge")

	var dodge_timer = Timer.new()
	dodge_timer.wait_time = dodge_duration
	dodge_timer.one_shot = true
	add_child(dodge_timer)
	dodge_timer.connect("timeout", Callable(self, "_end_dodge"))
	dodge_timer.start()

func _end_dodge():
	if is_dodging:
		self.modulate = Color(1, 1, 1, 1)  # Reset modulation
		is_dodging = false
		hurt_box.set("disabled", false)  # Re-enable hurtbox collision
		speed /= dodge_speed_multiplier  # Reset speed


func current_gun():
	if Globals.current_weapon == null:
		Globals.current_weapon = ar_gun		
	
func shoot_gun():
	if is_dodging or !reload_timer.is_stopped():
		return  # Prevent shooting while reloading or dodging

	if Globals.current_ammo > 0:
		Globals.decrement_ammo()
		_update_health_ui_ammo_label()

		# Fire the gun (existing logic here)
		var bullet = gun_fire_scene.instantiate()
		match current_dir:
			"right": bullet.direction = Vector2(1, 0)
			"left": bullet.direction = Vector2(-1, 0)
			"down": bullet.direction = Vector2(0, 1)
			"up": bullet.direction = Vector2(0, -1)
		bullet.global_position = gun.global_position + bullet.direction * gun.gun_length
		
		# Debug logs
		print("Bullet instantiated at:", bullet.global_position)
		print("Gun global position:", gun.global_position)
		print("Gun direction:", bullet.direction)

		get_tree().current_scene.add_child(bullet)
	else:
		start_reloading()


func start_reloading():
	if reload_timer.is_stopped():
		reload_label.visible = true
		reload_label.text = "Reloading..."
		reload_timer.start()

func _on_reload_finished():
	Globals.reload_ammo()
	_update_health_ui_ammo_label()
	reload_label.visible = false  # Hide the reloading text
	
func _update_health_ui_ammo_label():
	if health_ui and health_ui.has_method("update_ammo_label"):
		health_ui.update_ammo_label(Globals.current_ammo)
	else:
		print("HealthUI or update_ammo_label() method not found!")
		
func attack():
	if is_attacking or is_hurt or is_dodging:
		return
	is_attacking = true

	match current_dir:
		"right":
			anim.play("right_attack")
		"left":
			anim.play("left_attack")
		"down":
			anim.play("front_attack")
		"up":
			anim.play("back_attack")

	var attack_timer = Timer.new()
	attack_timer.wait_time = 0.4
	attack_timer.one_shot = true
	add_child(attack_timer)
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
	attack_box.set("enabled", true)
	attack_timer.start()

func _on_attack_timer_timeout():
	is_attacking = false
	attack_box.set("enabled", false)

func _on_animation_finished(animation_name: String):
	if animation_name.ends_with("dodge"):
		if is_dodging:  # Safety check
			print("Resetting modulation from animation.")
			sprite.modulate = Color(1, 1, 1, 1)  # Reset modulation
			is_dodging = false
			hurt_box.set("disabled", false)  # Re-enable hurtbox collision
			speed /= dodge_speed_multiplier  # Reset speed to normal
	elif animation_name.ends_with("attack"):
		is_attacking = false
		attack_box.set("enabled", false)
	elif animation_name.ends_with("hurt"):
		is_hurt = false

	# Play idle animation if no state is active
	if not is_attacking and not is_hurt and not is_dodging:
		play_idle_animation()


func _on_attack_box_body_entered(body):
	if body.has_method("take_damage") and is_attacking:
		body.take_damage(attack_damage)

func take_damage(amount: int):
	Globals.take_damage(amount)  # Update health globally
	print("Current health:", Globals.player_current_health)
	is_hurt = true
	is_attacking = false  # Cancel attack if hurt

	# Play the hurt animation based on direction
	match current_dir:
		"right":
			anim.play("right_hurt")
		"left":
			anim.play("left_hurt")
		"down":
			anim.play("front_hurt")
		"up":
			anim.play("back_hurt")

	# Start a timer to handle hurt state duration
	var hurt_timer = Timer.new()
	hurt_timer.wait_time = 0.5
	hurt_timer.one_shot = true
	add_child(hurt_timer)
	hurt_timer.connect("timeout", Callable(self, "_on_hurt_timer_timeout"))
	hurt_timer.start()

	if Globals.player_current_health <= 0:
		anim.play("die")
		anim.connect("animation_finished", Callable(self, "_on_death_animation_finished"))

func _on_death_animation_finished(animation_name: String) -> void:
	# Check if the completed animation is the "die" animation
	if animation_name == "die":
		anim.disconnect("animation_finished", Callable(self, "_on_death_animation_finished"))  # Disconnect signal
		_transition_to_next_scene()

func _transition_to_next_scene() -> void:
	# Instantiate and play the transition animation
	#var transition_instance = Scene_transition.instantiate()
	#get_tree().current_scene.add_child(transition_instance)

	#var animation_player = transition_instance.get_node("AnimationPlayer")
	#animation_player.play("fade_to_black")
	#await animation_player.animation_finished

	# Change to the next scene
	get_tree().change_scene_to_file("res://Scenes/gameover.tscn")
	
func _on_hurt_timer_timeout():
	is_hurt = false
	play_idle_animation()
