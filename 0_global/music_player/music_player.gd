extends Node2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

var fading := false

func fade_music_out_in(time: float, volume: float = 12) -> void:
	if not fading:
		var tween = create_tween()
		tween.tween_property(audio_stream_player,
				"volume_db", audio_stream_player.volume_db - volume, time / 2)
		fading = true
		await tween.finished
		var tween2 = create_tween()
		tween2.tween_property(audio_stream_player,
				"volume_db", audio_stream_player.volume_db + volume, time / 2)
		await tween2.finished
		fading = false
