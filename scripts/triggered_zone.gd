extends Area2D

@export var length = 0

@onready var hidden_platforms: TileMapLayer = $"../HiddenPlatforms"
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _on_ready() -> void:
	collision_shape_2d.shape.b.x = length


func _on_body_entered(_body: Node2D) -> void:
	# add code to check coins collected
	# spawn invisible fish on game load
	# release when all conditions are met
	print("tripped")
	hidden_platforms.show()
	print("made it here")
	hidden_platforms.enabled = true
	hidden_platforms.collision_enabled = true
	print("made it here 2")
