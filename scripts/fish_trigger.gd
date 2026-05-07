extends Node2D

@onready var camera_2d: Camera2D = $"../../Player/Camera2D"
@onready var goldfishes: Node2D = $Goldfishes

func trigger() -> void:
	goldfishes.show()
	# need to add some method to pause the player camera lerping during cutscenes
	#var tween = get_tree().create_tween()
	#tween.tween_property(camera_2d, "offset", Vector2(0, -80), .7)
