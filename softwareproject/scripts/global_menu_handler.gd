extends Node

var menu_scene : PackedScene = preload("res://addons/maaacks_options_menus/base/scenes/menus/options_menu/master_options_menu_with_tabs.tscn")
var menu_instance : Control = null  # Explicitly specify Control type

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key by default
		if menu_instance == null:
			# Open the menu
			menu_instance = menu_scene.instantiate()
			add_child(menu_instance)
			menu_instance.grab_focus()

			# Pause the game
			get_tree().paused = true
		else:
			# Close the menu
			menu_instance.queue_free()
			menu_instance = null

			# Unpause the game only if the menu is closed
			if get_tree().has_node(menu_instance.get_path()):
				menu_instance = null
			else:
				get_tree().paused = false
