@tool
extends Parallax2D

@export_range(-0.1, 0.1, 0.01) var speed_x := 0.05:
	set(value):
		speed_x = value
		_update_shader.call_deferred("speed_x")
@export_range(-0.1, 0.1, 0.01) var speed_y := 0.01:
	set(value):
		speed_y = value
		_update_shader.call_deferred("speed_y")
@export_range(0.0, 1.0, 0.05) var gap_density = 0.5:
	set(value):
		gap_density = value
		_update_shader.call_deferred("gap_density")
@export_range(0.0, 1.0, 0.01) var density = 0.25:
	set(value):
		density = value
		_update_shader.call_deferred("density")


func _ready():
	_update_shader("gap_density")
	_update_shader("density")
	_update_shader("speed_x")
	_update_shader("speed_y")


func _update_shader(mode: String) -> void:
	var tmp = Vector2(speed_x, speed_y)
	for child in get_children():
		match mode:
			"gap_density":
				child.set_instance_shader_parameter(mode, gap_density)
			"density":
				child.set_instance_shader_parameter(mode, density)
			"speed_x":
				child.set_instance_shader_parameter(mode, tmp.x)
				tmp.x = (sign(tmp.x) * abs(tmp.x) + (abs(tmp.x) * 0.4))
			"speed_y":
				child.set_instance_shader_parameter(mode, tmp.y)
