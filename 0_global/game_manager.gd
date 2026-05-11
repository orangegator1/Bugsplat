extends Node

var score = 0
var possible_score = 0
enum window {H_1080,H_810,H_540}
var window_sizes: Array[Vector2i] = [
	Vector2i(1920,1080),
	Vector2i(1440,810),
	Vector2i(960,540),
]
var window_size := window.H_810
var preferred_size := window.H_810
var viewport_size := Vector2i(480, 270)

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(window_sizes[window_size])


func _process(_delta):
	if Input.is_action_just_pressed("reset_scene"):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_window_size_and_mode()


#func add_point():
	#score += 1
	#if score == possible_score:
		#coins_progress.text = "Seek\nbelow"
	#else:
		#coins_progress.text = str(score) + "/" + str(possible_score) + "\ncoins"


func add_possible_point():
	possible_score += 1


func toggle_window_size_and_mode() -> void:

	if window_size == window.H_1080 or window_size == window.H_810:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if window_size == window.H_1080:
			window_size = window.H_810
			DisplayServer.window_set_size(window_sizes[window_size])
			preferred_size = window_size
		else:
			DisplayServer.window_set_size(Vector2i(960,540))
			window_size = window.H_540
			preferred_size = window_size
		@warning_ignore("integer_division")
		var window_position = DisplayServer.screen_get_position(0) \
			+ DisplayServer.screen_get_size(0)/2 \
			- DisplayServer.window_get_size()/2
		DisplayServer.window_set_position(window_position)
	elif DisplayServer.window_get_size().x < 1920:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_size(Vector2i(1920,1080))
		window_size = window.H_1080
		preferred_size = window_size
