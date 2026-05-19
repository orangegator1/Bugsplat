extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D

var picked := false

func _on_body_entered(_body: Node2D) -> void:
	MessageBus.player_health_changed.emit(1)
	animation_player.play("Pickup")
