extends Area2D

func _ready() -> void:
	monitoring = false
	SceneManager.load_scene_finished.connect(enable_monitoring)

func _on_body_entered(_body: Node2D) -> void:
	var player = await SceneManager.get_player()
	var _player_pos = player.global_position
	var _tmp = global_position
	SceneManager.reset()

func enable_monitoring() -> void:
	await get_tree().process_frame
	monitoring = true
