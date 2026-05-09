extends Node2D

# level 1
var current_level := "uid://b5tobrceh3joe"
var level: Node2D


#func _process(_delta: float) -> void:
func _ready() -> void:
	# wasn't working without waiting a frame
	await get_tree().process_frame

	level = load(current_level).instantiate()
	get_tree().root.add_child(level)


func load_scene(new_level: String) -> void:
	if not new_level == current_level:

		# allow current level to be unloaded so that correct level_transition
		# position can be identified to place the player
		level.queue_free.call_deferred()
		await get_tree().process_frame

		current_level = new_level
		level = load(current_level).instantiate()
		get_tree().root.add_child(level)
