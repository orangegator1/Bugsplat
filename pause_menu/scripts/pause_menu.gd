class_name PauseMenu extends CanvasLayer

@onready var pause_screen: Control = %PauseScreen
@onready var system: Control = %System

@onready var back_button: Button = %BackButton
@onready var system_menu_button: Button = %SystemMenuButton
@onready var map: Control = %Map
@onready var inventory: Label = %Inventory
@onready var map_label: Label = %MapLabel

@onready var system_back_button: Button = %SystemBackButton
@onready var back_to_map_button: Button = %BackToMapButton
@onready var back_to_title_button: Button = %BackToTitleButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var sound_effect_player: SoundPlayer = $System/SoundEffectPlayer

var title_path := "res://title_screen/TitleScreen.tscn"
var player: Player
var map_focused: bool = false
var initial_map_pos: Vector2
var map_scroll_velocity: Vector2
const SCROLL_V := 120.0

func _ready() -> void:
	player = await SceneManager.get_player()
	show_pause_screen()
	initial_map_pos = map.position
	system_menu_button.pressed.connect(show_system_menu)
	back_button.pressed.connect(unpause)

	setup_system_menu()


func _process(delta: float) -> void:
	map_scroll_velocity = map_scroll_velocity.clamp(
			Vector2(-SCROLL_V, -SCROLL_V),
			Vector2(SCROLL_V, SCROLL_V)
		)
	map.position += map_scroll_velocity * delta
	print(map_scroll_velocity)

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
	system_back_button.pressed.connect(unpause)


func on_back_to_title_pressed() -> void:
	SceneManager.initiated_from_pause_menu = true
	SceneManager.transition_scene_to_title(title_path, "down")
	get_tree().paused = false
	await SceneManager.new_scene_ready
	self.visible = false
	await SceneManager.load_scene_finished
	SceneManager.initiated_from_pause_menu = false
	self.queue_free()
	player.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		unpause()
	if not map_focused:
		if pause_screen.visible == true:
			if event.is_action_pressed("right"):
				system_menu_button.grab_focus()
			elif (event.is_action_pressed("left")
					or event.is_action_pressed("ui_up")):
				back_button.grab_focus()
			elif event.is_action_pressed("down"):
				get_viewport().set_input_as_handled()
				focus_map()
	else:
		if (event.is_action_pressed("ui_cancel")):
			unfocus_map()
		elif event.is_action_pressed("right"):
			map_scroll_velocity += Vector2(-SCROLL_V,0)
		elif event.is_action_pressed("left"):
			map_scroll_velocity += Vector2(SCROLL_V,0)
		elif event.is_action_pressed("down"):
			map_scroll_velocity += Vector2(0,-SCROLL_V)
		elif event.is_action_pressed("ui_up"):
			map_scroll_velocity += Vector2(0,SCROLL_V)
		elif event.is_action_pressed("interact"):
			zoom()
		elif event.is_action_pressed("jump"):
			zoom(false)
		elif (event.is_action_released("right")
				or event.is_action_released("left")):
			map_scroll_velocity.x = 0
		elif (event.is_action_released("down")
				or event.is_action_released("ui_up")):
			map_scroll_velocity.y = 0


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


func unpause() -> void:
	get_viewport().set_input_as_handled()
	get_tree().paused = false
	self.queue_free.call_deferred()


func focus_map() -> void:
	if not map_focused:
		inventory.visible = false
		map_label.visible = false
		system_menu_button.visible = false

		map_focused = true
		map.grab_focus()
		zoom()


func unfocus_map() -> void:
	if map_focused:
		inventory.visible = true
		map_label.visible = true
		system_menu_button.visible = true

		map_focused = false
		map.scale = Vector2.ONE
		map.pivot_offset = Vector2.ZERO
		map.position = initial_map_pos
		%PlayerIndicator.scale = Vector2.ONE


func zoom(zoom_in := true) -> void:
	# TODO pivot instead on center of visible map
	if zoom_in and map.scale.y < 16:
		map.scale *= 2
		map.pivot_offset = %PlayerIndicator.position
	elif not zoom_in and map.scale.y > 1 / 2.0:
		map.scale /= 2
		map.pivot_offset = %PlayerIndicator.position
	%PlayerIndicator.scale = Vector2.ONE / map.scale
