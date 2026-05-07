extends AudioStreamPlayer2D

@onready var music_player: AudioStreamPlayer = $music_player

var fading := false

func fade_music_out_in(time: float, volume: float = 12) -> void:
	if not fading:
		var tween = create_tween()
		tween.tween_property(music_player,
				"volume_db", music_player.volume_db - volume, time / 2)
		fading = true
		await tween.finished
		var tween2 = create_tween()
		tween2.tween_property(music_player,
				"volume_db", music_player.volume_db + volume, time / 2)
		await tween2.finished
		fading = false
