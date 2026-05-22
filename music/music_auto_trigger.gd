@icon("uid://djivvgdukyoc5")

class_name MusicAutoTrigger extends Node

@export var track: AudioStream
@export var reverb: Audio.REVERB_TYPE = Audio.REVERB_TYPE.NONE

func _ready() -> void:
	Audio.play_music(track)
	Audio.set_reverb(reverb)
