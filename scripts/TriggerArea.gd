extends Area2D

@onready var fish_trigger: Node2D = $FishTrigger
var triggered = false

func _on_body_entered(_body: Node2D) -> void:
	if fish_trigger.trigger():
		triggered = true
	else:
		GameManager.change_scene("Scene2")
