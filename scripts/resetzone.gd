extends Area2D

@onready var timer: Timer = $Timer
@onready var player: CharacterBody2D

func _ready() -> void:
	player = await SceneManager.get_player()

func _on_body_entered(body: Node2D) -> void:
	if not player:
		player = await SceneManager.get_player()

	player.sound_effect_player.play("bugsplat")
	Engine.time_scale = 0.3
	body.get_node("CollisionShape2D").queue_free()
	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
