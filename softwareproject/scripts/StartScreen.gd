# StartScreen.gd
extends Control

@onready var background_music = $AudioStreamPlayer


func _ready():
	if not background_music.playing:
		background_music.play()
	
	if $StartButton:
		$StartButton.pressed.connect(_on_start_button_pressed)
	else:
		print("Error: StartButton not found")

	if $SettingsButton:
		$SettingsButton.pressed.connect(_on_settings_button_pressed)
	else:
		print("Error: SettingsButton not found")

	if $QuitButton:
		$QuitButton.pressed.connect(_on_quit_button_pressed)
	else:
		print("Error: SoundButton not found")

	if $Tutorial:
		$Tutorial.pressed.connect(_on_tutorial_button_pressed)
	else:
		print("Error: StartButton not found")

func _on_start_button_pressed():
	reset_game()
	background_music.stop()
	get_tree().change_scene_to_file("res://introscene.tscn")
	
func reset_game():
	# Reset any global variables
	Globals.player_current_health = Globals.player_max_health
	Globals.current_ammo = Globals.max_ammo
	Globals.coin_count = 0

	# You can also reset any other game-specific states, such as scores, timers, or inventories
	print("Game state has been reset.")
func _on_settings_button_pressed():
	# Open the options menu or perform another action
	print("Options button pressed")
	get_tree().change_scene_to_file("res://addons/maaacks_options_menus/base/scenes/menus/options_menu/master_options_menu_with_tabs.tscn")
	
func _on_quit_button_pressed():
	# Open the options menu or perform another action
	print("Sound button pressed")
	get_tree().quit()
	
func _on_tutorial_button_pressed():
	reset_game()
	background_music.stop()
	get_tree().change_scene_to_file("res://Scenes/tutorial.tscn")
