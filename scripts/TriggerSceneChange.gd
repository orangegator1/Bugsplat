extends Area2D

@onready var prompt: Sprite2D = $"CollisionShape2D/E prompt"
@export var scene = "Scene2"
@onready var fish_trigger: Node2D = $FishTrigger
var triggered = false
var triggerable = false

func _on_body_entered(_body: Node2D) -> void:
	triggerable = true;
	prompt.show()
	if not triggered:
		triggered = true
	fish_trigger.trigger()


func _on_body_exited(_body: Node2D) -> void:
	triggerable = false;
	prompt.hide()


func _input(event):
	if triggerable and event.is_action_pressed("interact"):
		_trigger()


func _trigger():
	GameManager.change_scene(scene)
