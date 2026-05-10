extends Node2D

@export var speed = 140
@export var slow = false
@export var min_playback_speed = 0.66

var playback_speed = randf()
const NUM_FRAMES = 8

@onready var trigger_scene_2: Area2D = $"../.."
@onready var fish_trigger: Node2D = $"../.."
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var i = 0

func _process(delta: float) -> void:
	if trigger_scene_2.triggered:
		if i == 0:
			i += 1

			# modulate to get values from +-1 to +-min_playback_speed
			# slow fish have half the speed range
			var tmp = playback_speed
			tmp *= (1 - min_playback_speed) / (int(slow) + 1)
			tmp += min_playback_speed
			if playback_speed > 0.5:
				playback_speed = -tmp
			else:
				playback_speed = tmp

			animated_sprite.play("swim",playback_speed)
			var offset = randi() % NUM_FRAMES
			animated_sprite.frame = offset

		# move speed based on animation frame rate
		position.x += delta * speed * abs(playback_speed)
