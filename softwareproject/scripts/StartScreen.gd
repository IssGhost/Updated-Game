# StartScreen.gd
extends Control

@onready var background_music = $AudioStreamPlayer


func _ready():
	if not background_music.playing:
		background_music.play()
	
	if $VBoxContainer/StartButton:
		$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	else:
		print("Error: StartButton not found")

	if $VBoxContainer/SettingsButton:
		$VBoxContainer/SettingsButton.pressed.connect(_on_settings_button_pressed)
	else:
		print("Error: SettingsButton not found")

	if $VBoxContainer/SoundButton:
		$VBoxContainer/SoundButton.pressed.connect(_on_sound_button_pressed)
	else:
		print("Error: SoundButton not found")


func _on_start_button_pressed():
	background_music.stop()
	get_tree().change_scene_to_file("res://introscene.tscn")

func _on_settings_button_pressed():
	# Open the options menu or perform another action
	print("Options button pressed")
	VideoSettings.show()
	
func _on_sound_button_pressed():
	# Open the options menu or perform another action
	print("Sound button pressed")
	AudioSettings.show()
