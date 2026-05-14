extends Sprite2D
@onready var camera_2d: Camera2D = $".."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position = camera_2d.global_position + camera_2d.offset + Vector2(0,-30)
