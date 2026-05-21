class_name SoundPlayer extends AnimationPlayer

func play_sound(audio: AudioStream, pos: Vector2) -> void:
	# Check if a primary player exists and is playing
	# Create a new, temporary player
	if is_playing:
		var audio_player  = AudioStreamPlayer2D.new()
		add_child(audio_player)
		audio_player.bus = "SFX"
		audio_player.global_position = pos
		audio_player.stream = audio
		audio_player.finished.connect(audio_player.queue_free)
		audio_player.play()
	else:
		play()

func play_sound_global(audio: AudioStream) -> void:
	var audio_player  = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = "UI"
	audio_player.stream = audio
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()
