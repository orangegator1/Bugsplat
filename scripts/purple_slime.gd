extends Node2D

var speed = 50
var dir = 1
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		dir = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		dir = 1
		animated_sprite.flip_h = false
	position.x += dir * speed * delta
