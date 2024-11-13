extends CharacterBody2D

signal health_changed(new_health)  # Signal to notify health changes

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var gunanim: AnimationTree = $Node2D/ArGun/AnimationTree
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_box: Area2D = $AttackBox
@onready var hurt_box: Area2D = $Hurtbox
@onready var sound_effect = $AudioStreamPlayer2D
@export var speed = 1000
@export var attack_damage = 10
@export var max_health: int = 500

@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var gun = $Node2D/ArGun
@export var gun_fire_scene: PackedScene = preload("res://Scenes/gun_fire.tscn")

var current_dir = "none"
var is_attacking = false
var is_hurt = false
var current_health: int = max_health

func _ready():
	anim.play("front_idle")
	attack_box.connect("body_entered", Callable(self, "_on_attack_box_body_entered"))
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))
	add_to_group("player")
	reset_state()

func reset_state():
	is_attacking = false
	is_hurt = false

func _physics_process(delta):
	if not is_attacking and not is_hurt:
		player_movement(delta)

var gamestart_initial_direction = false

func player_movement(delta):
	if gamestart_initial_direction == false:
		current_dir = "down"
		gamestart_initial_direction = true
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
	if is_attacking or is_hurt:
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
	if event.is_action_pressed("shoot"):  # Define "shoot" in your input map
		shoot_gun()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("dialogue"):
		print("dialouge")
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			print("dialouge working")

			actionables[0].action()
			return
			
			
func shoot_gun():
	if gun == null:
		print("Error: Gun node not found.")
		return

	var bullet = gun_fire_scene.instantiate()
	
	# Determine bullet direction based on player direction
	match current_dir:
		"right":
			bullet.direction = Vector2(1, 0)
		"left":
			bullet.direction = Vector2(-1, 0)
		"down":
			bullet.direction = Vector2(0, 1)
		"up":
			bullet.direction = Vector2(0, -1)

	# Set the bullet's initial position at the gun's position
	bullet.global_position = gun.global_position + bullet.direction * gun.gun_length

	# Add the bullet to the current scene
	get_tree().current_scene.add_child(bullet)
	
func attack():
	if is_attacking or is_hurt:
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
	if animation_name.ends_with("attack"):
		is_attacking = false
		attack_box.set("enabled", false)
	elif animation_name.ends_with("hurt"):
		is_hurt = false

	play_idle_animation()

func _on_attack_box_body_entered(body):
	if body.has_method("take_damage") and is_attacking:
		body.take_damage(attack_damage)

func take_damage(amount: int):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	is_hurt = true
	is_attacking = false  # Cancel attack if hurt

	# Emit the health_changed signal to update the UI
	emit_signal("health_changed", current_health)

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

	if current_health <= 0:
		velocity = Vector2.ZERO

func _on_hurt_timer_timeout():
	is_hurt = false
	play_idle_animation()
