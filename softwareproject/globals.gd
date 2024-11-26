extends Node

var is_finished: String = ""
var coin_count: int = 0

signal transition_to_boss_room

func add_coin():
	coin_count += 1
	print("Coins collected:", coin_count)

func reset_coins():
	coin_count = 0
