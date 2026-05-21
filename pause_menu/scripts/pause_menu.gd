class_name PauseMenu extends CanvasLayer

@onready var pause_screen: Control = %PauseScreen
@onready var system: Control = %System

@onready var back_button: Button = %BackButton
@onready var system_menu_button: Button = %SystemMenuButton
@onready var back_to_map_button: Button = %BackToMapButton
@onready var back_to_title_button: Button = %BackToTitleButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var sound_effect_player: SoundPlayer = $System/SoundEffectPlayer

var title_path := "res://title_screen/TitleScreen.tscn"
var player: Player

func _ready() -> void:
	player = await SceneManager.get_player()
	show_pause_screen()
	system_menu_button.pressed.connect(show_system_menu)

	setup_system_menu()


func show_pause_screen() -> void:
	pause_screen.visible = true
	system.visible = false


func show_system_menu() -> void:
	pause_screen.visible = false
	system.visible = true
	back_to_map_button.grab_focus()


func setup_system_menu() -> void:
	music_slider.value = AudioServer.get_bus_volume_linear(1)
	sfx_slider.value = AudioServer.get_bus_volume_linear(2)
	ui_slider.value = AudioServer.get_bus_volume_linear(3)

	music_slider.value_changed.connect(on_music_slider_changed)
	sfx_slider.value_changed.connect(on_sfx_slider_changed)
	ui_slider.value_changed.connect(on_ui_slider_changed)

	back_to_map_button.pressed.connect(show_pause_screen)
	back_to_title_button.pressed.connect(on_back_to_title_pressed)


func on_back_to_title_pressed() -> void:
	SceneManager.initiated_from_pause_menu = true
	SceneManager.transition_scene_to_title(title_path, "down")
	get_tree().paused = false
	await SceneManager.load_scene_finished
	SceneManager.initiated_from_pause_menu = false
	self.queue_free()
	player.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		self.queue_free.call_deferred()

	if pause_screen.visible == true:
		if event.is_action_pressed("right"):
			system_menu_button.grab_focus()


func on_music_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(1, value)
	SaveManager.save_config()


func on_sfx_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)
	sound_effect_player.play_sound(SFX.bugsplat, player.global_position)
	SaveManager.save_config()


func on_ui_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(3, value)
	sound_effect_player.play_sound_global(SFX.bugsplat)
	SaveManager.save_config()
