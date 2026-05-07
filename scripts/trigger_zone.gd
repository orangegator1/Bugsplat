extends Area2D

@export var length = 200
@onready var hidden_platforms: TileMapLayer = $"../HiddenPlatforms"
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D





func _on_body_entered(_body: Node2D) -> void:
	hidden_platforms.show()
	hidden_platforms.enabled = true
	hidden_platforms.collision_enabled = true
