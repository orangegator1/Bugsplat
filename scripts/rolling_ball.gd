extends RigidBody2D

var speed = 0
var dir = 0

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _process(delta: float) -> void:
	if ray_cast_right.is_colliding():
		print("right colliding")
		dir = 1
		animated_sprite.play_backwards()
	if ray_cast_left.is_colliding():
		print("left colliding")
		dir = -1
		animated_sprite.play()
	speed = 30
	position.x += dir * speed * delta
