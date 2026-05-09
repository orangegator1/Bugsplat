extends Area2D

@onready var prompt: Sprite2D = $"CollisionShape2D/E prompt"
@onready var goldfishes: Node2D = $Goldfishes
var triggered = false
var triggerable = false

func _on_body_entered(_body: Node2D) -> void:
	triggerable = true;
	#prompt.show()
	if not triggered:
		triggered = true
	goldfishes.show()


func _on_body_exited(_body: Node2D) -> void:
	triggerable = false;
	prompt.hide()


#func _input(event):
	#if triggerable and event.is_action_pressed("interact"):
		#_trigger()
#
#
#func _trigger():
	#GameManager.change_scene(scene)
