class_name PauseMenu extends CanvasLayer

@onready var pause_screen: Control = %PauseScreen
@onready var system: Control = %System

@onready var back_button: Button = %BackButton
@onready var system_menu_button: Button = %SystemMenuButton
@onready var map: Control = %Map
@onready var map_overlay: ColorRect = $PauseScreen/Control/Map/MapOverlay
@onready var inventory: Control = %InventoryMenu
@onready var inventory_full: Control = %InventoryFull
@onready var inventory_overlay: ColorRect = $PauseScreen/Control/InventoryMenu/InventoryOverlay
@onready var inventory_label: Label = %InventoryLabel
@onready var map_label: Label = %MapLabel

@onready var system_back_button: Button = %SystemBackButton
@onready var back_to_map_button: Button = %BackToMapButton
@onready var back_to_title_button: Button = %BackToTitleButton
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider

var title_path := "res://title_screen/TitleScreen.tscn"
var player: Player
var map_selected: bool = false
var inventory_focused: bool = false
var initial_map_pos: Vector2
var map_scroll_velocity: Vector2
const SCROLL_V := 120.0

func _ready() -> void:
	player = await SceneManager.get_player()
	initial_map_pos = map.position
	system_menu_button.pressed.connect(show_system_menu)
	back_button.pressed.connect(unpause)

	# debug
	inventory.focus_entered.connect(inventory_on_focus_entered)
	inventory.focus_exited.connect(inventory_on_focus_entered.bind(false))
	map.focus_entered.connect(map_on_focus_entered)
	map.focus_exited.connect(map_on_focus_entered.bind(false))

	show_pause_screen()

	Audio.setup_button_audio_manual(map)
	Audio.setup_button_audio_manual(inventory)
	Audio.setup_button_audio(self)

	setup_system_menu()


func _process(delta: float) -> void:
	map_scroll_velocity = map_scroll_velocity.clamp(
			Vector2(-SCROLL_V, -SCROLL_V),
			Vector2(SCROLL_V, SCROLL_V)
		)
	map.position += map_scroll_velocity * delta


func inventory_on_focus_entered(entered = true):
	if entered:
		inventory_overlay.modulate = Color("84ffee1a")
	else:
		inventory_overlay.modulate = Color(0.0, 0.0, 0.0, 0.0)
	inventory_focused = entered
	inventory_overlay.visible = entered


func map_on_focus_entered(entered = true):
	if entered:
		map_overlay.modulate = Color(0.518, 1.0, 0.933, 0.1)
	else:
		map_overlay.modulate = Color(0.0, 0.0, 0.0, 0.0)
	map_overlay.visible = entered


func show_pause_screen() -> void:
	pause_screen.visible = true
	system.visible = false
	inventory_full.visible = false
	map.grab_focus()


func show_system_menu() -> void:
	pause_screen.visible = false
	system.visible = true
	back_to_map_button.grab_focus()


func setup_system_menu() -> void:
	music_slider.value = AudioServer.get_bus_volume_linear(2)
	sfx_slider.value = AudioServer.get_bus_volume_linear(3)
	ui_slider.value = AudioServer.get_bus_volume_linear(4)

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

	if map.has_focus():
		if (event.is_action_pressed("ui_accept")):
			select_map()

	if map_selected:
		if (event.is_action_pressed("ui_cancel")):
			unselect_map()
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
	elif not inventory.selected and event.is_action_pressed("ui_cancel"):
		unpause()


func select_map() -> void:
	if not map_selected:
		inventory_label.visible = false
		inventory.visible = false
		map_label.visible = false
		system_menu_button.visible = false
		back_button.visible = false

		Audio.play_ui_audio(Audio.ui_focus_audio)
		map_selected = true
		map.grab_focus()
		zoom()


func unselect_map() -> void:
	if map_selected:
		Audio.play_ui_audio(Audio.ui_cancel_audio)
		inventory.visible = true
		inventory_label.visible = true
		map_label.visible = true
		system_menu_button.visible = true
		back_button.visible = true

		map_selected = false
		map.scale = Vector2.ONE
		map.pivot_offset = Vector2.ZERO
		map.position = initial_map_pos
		map_scroll_velocity = Vector2.ZERO
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


func on_music_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)
	SaveManager.save_config()


func on_sfx_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(3, value)
	Audio.play_sound(Audio.bugsplat, player.global_position)
	SaveManager.save_config()


func on_ui_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(4, value)
	Audio.play_sound_global(Audio.bugsplat)
	SaveManager.save_config()


func unpause() -> void:
	get_viewport().set_input_as_handled()
	get_tree().paused = false
	self.queue_free.call_deferred()
