extends Control

@export var Scene_transition: PackedScene = preload("res://Scenes/Scene_transition.tscn")

func _ready():
	# Instantiate the transition scene
	var transition_instance = Scene_transition.instantiate()
	get_tree().current_scene.add_child(transition_instance)

	# Ensure the ColorRects in the transition cover the screen
	_resize_color_rects(transition_instance)

	# Play the animation
	var animation_player = transition_instance.get_node("AnimationPlayer")
	animation_player.play("eye_open")


func _resize_color_rects(transition_instance: Node):
	var screen_size = get_viewport().size
	print("Viewport size: ", screen_size)

	var eye_top = transition_instance.get_node("Eye_top")
	var eye_bottom = transition_instance.get_node("Eye_bottom")

	print("Eye_top exists: ", eye_top != null)
	print("Eye_bottom exists: ", eye_bottom != null)

	if eye_top is ColorRect:
		# Set Eye_top to occupy the top half of the screen
		eye_top.anchor_left = 0
		eye_top.anchor_top = 0
		eye_top.anchor_right = 1
		eye_top.anchor_bottom = 0.5  # Bottom of Eye_top ends at half the screen
		eye_top.offset_left = 0
		eye_top.offset_top = 0
		eye_top.offset_right = 0
		eye_top.offset_bottom = 0  # Fully stretched to anchors
		print("Eye_top offsets AFTER: ", eye_top.offset_left, eye_top.offset_top, eye_top.offset_right, eye_top.offset_bottom)

	if eye_bottom is ColorRect:
		# Set Eye_bottom to occupy the bottom half of the screen
		eye_bottom.anchor_left = 0
		eye_bottom.anchor_top = 0.5  # Starts at the middle of the screen
		eye_bottom.anchor_right = 1
		eye_bottom.anchor_bottom = 1  # Ends at the bottom of the screen
		eye_bottom.offset_left = 0
		eye_bottom.offset_top = 0
		eye_bottom.offset_right = 0
		eye_bottom.offset_bottom = 0  # Fully stretched to anchors
		print("Eye_bottom offsets AFTER: ", eye_bottom.offset_left, eye_bottom.offset_top, eye_bottom.offset_right, eye_bottom.offset_bottom)
