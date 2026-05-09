@icon("uid://cbh2s2me8kj8o")
class_name PlayerSpawn extends Node2D

func _ready() -> void:
	visible = false
	await get_tree().process_frame


func _process(_delta: float) -> void:
	if not get_tree().get_first_node_in_group("Player"):
		var player = load("uid://npxpcfoo6wdd").instantiate()
		player.add_to_group("Player")
		get_tree().root.add_child(player)
		player.global_position = global_position
	else:
		return
