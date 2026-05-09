extends Node2D

var level

func _process(_delta: float) -> void:
	if is_inside_tree() and not level:
		level = load("uid://b5tobrceh3joe").instantiate()
		get_tree().root.add_child(level)
