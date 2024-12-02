extends Area2D

signal player_entered(room_id)
signal enemy_exited(room_id)
var room_id: int

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "on_body_exited"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("player_entered", room_id)
	
func _on_body_exited(body):
	if body.is_in_group("enemy"):
		emit_signal("enemy_exited")
	
