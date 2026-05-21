extends Node

enum window {H_1080,H_810,H_540}
var window_sizes: Array[Vector2i] = [
	Vector2i(1920,1080),
	Vector2i(1440,810),
	Vector2i(960,540),
]
var preferred_size := window.H_810
var viewport_size := Vector2i(480, 270)

func _ready() -> void:
	await SaveManager.config_loaded
	set_size(preferred_size)


func _process(_delta):
	if Input.is_action_just_pressed("reset_scene"):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("toggle_fullscreen"):
		toggle_window_size_and_mode()


func toggle_window_size_and_mode() -> void:
	if preferred_size == window.H_1080:
		set_size(window.H_810)
	elif preferred_size == window.H_810:
		set_size(window.H_540)
	elif preferred_size == window.H_540:
		set_size(window.H_1080)


func set_size(new_size: window) -> void:
	if new_size == window.H_1080:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	DisplayServer.window_set_size(window_sizes[new_size])

	if not new_size == window.H_1080:
		@warning_ignore("integer_division")
		var window_position = (DisplayServer.screen_get_position(0)
				+ DisplayServer.screen_get_size(0) / 2
				- DisplayServer.window_get_size() / 2)
		DisplayServer.window_set_position(window_position)

	preferred_size = new_size
	SaveManager.save_config()
