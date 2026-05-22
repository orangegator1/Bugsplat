extends Node

enum REVERB_TYPE {NONE, SMALL, MEDIUM, LARGE,}

const bugsplat = preload("uid://dntq5lwfpst2y")
const grow_up = preload("uid://0luclghebtcu")
const ledge_jump = preload("uid://d2nhpjdd8udiu")
const ledge_climb = preload("uid://5xqaln1jo0jd")
const heavy_landing = preload("uid://cc27w3uva0g43")

@export var ui_focus_audio: AudioStream
@export var ui_select_audio: AudioStream
@export var ui_cancel_audio: AudioStream
@export var ui_success_audio: AudioStream
@export var ui_error_audio: AudioStream

var current_track := 0
var music_tweens: Array[Tween]
var ui_audio_player: AudioStreamPlaybackPolyphonic

@onready var music_1: AudioStreamPlayer = %Music1
@onready var music_2: AudioStreamPlayer = %Music2
@onready var ui: AudioStreamPlayer = %UI

func _ready() -> void:
	# start up the stream
	ui.play()
	ui_audio_player = ui.get_stream_playback()


func play_music(audio: AudioStream) -> void:
	var current_player := get_music_player(current_track)
	# do nothing if this audio is already playing
	if current_player.stream == audio:
		return

	var next_track = wrapi(current_track + 1, 0, 2)
	var next_player := get_music_player(next_track)

	next_player.stream = audio
	next_player.play()

	for t in music_tweens:
		t.kill()
	music_tweens.clear()
	fade_track_out(current_player)
	fade_track_in(next_player)

	current_track = next_track


func fade_track_in(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_linear", 1.0, 1.0)


func fade_track_out(player: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	music_tweens.append(tween)
	tween.tween_property(player, "volume_linear", 0.0, 1.5)
	tween.tween_callback(player.stop)


func get_music_player(i: int) -> AudioStreamPlayer:
	if i == 0:
		return music_1
	else:
		return music_2


func set_reverb(type: REVERB_TYPE) -> void:
	print(type)


func play_sound(audio: AudioStream, pos: Vector2) -> void:
	var audio_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	add_child(audio_player)
	audio_player.bus = "SFX"
	audio_player.global_position = pos
	audio_player.stream = audio
	audio_player.finished.connect(audio_player.queue_free)
	audio_player.play()


func play_ui_audio(audio: AudioStream) -> void:
	if ui_audio_player:
		ui_audio_player.play_stream(audio)


func setup_button_audio(node: Node) -> void:
	for c in node.find_children("*", "Button"):
		c.pressed.connect(ui_select)
		c.focus_entered.connect(ui_focus_change)


func ui_focus_change() -> void:
	play_ui_audio(ui_focus_audio)


func ui_select() -> void:
	play_ui_audio(ui_select_audio)


func ui_cancel() -> void:
	play_ui_audio(ui_cancel_audio)


func ui_success() -> void:
	play_ui_audio(ui_success_audio)


func ui_error() -> void:
	play_ui_audio(ui_error_audio)
