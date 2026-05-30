class_name PauseMenu extends CanvasLayer

@onready var pause_screen: Control = %PauseScreen
@onready var system: Control = %System

@onready var back_button: Button = %BackButton
@onready var system_menu_button: Button = %SystemMenuButton
@onready var map: Control = %Map
@onready var map_overlay: ColorRect = %MapOverlay
@onready var inventory: Control = %InventoryMenu
@onready var inventory_full: Control = %InventoryFull
@onready var inventory_overlay: ColorRect = %InventoryOverlay
@onready var inventory_label: Label = %InventoryLabel
@onready var map_label: Label = %MapLabel
@onready var map_nodes: Control = %MapNodes

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
const HALF_SCREEN := Vector2(240, 117)

# debug zoom
@onready var debug_pivot_offset_marker: TextureRect = %DebugPivotOffset


func _ready() -> void:
	player = await SceneManager.get_player()
	initial_map_pos = map.position
	system_menu_button.pressed.connect(show_system_menu)
	back_button.pressed.connect(unpause)

	inventory.focus_entered.connect(inventory_on_focus_entered)
	inventory.focus_exited.connect(inventory_on_focus_entered.bind(false))
	map.focus_entered.connect(map_on_focus_entered)
	map.focus_exited.connect(map_on_focus_entered.bind(false))

	# center fullscreen map on centered on player indicator
	map.clip_contents = true
	map_nodes.position = ((-%PlayerIndicator.position / map.scale)
				+ HALF_SCREEN - Vector2(60, initial_map_pos.y))
	debug_pivot_offset_marker.visible = false
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
	# TODO figure out clamps, depends on map scale
	#var new_pos = map.position + (map_scroll_velocity * delta)
	#var top_left = Vector2(96, 32) * map.scale
	#var map_pos_clamped = new_pos.clamp(top_left, Vector2(10000, 10000))
	#map.position = map_pos_clamped

	map.position += map_scroll_velocity * delta
	debug_pivot_offset_marker.position -= map_scroll_velocity * delta / map.scale

	if map_selected:
		if (Input.is_action_pressed("ui_cancel")):
			unselect_map()
		elif Input.is_action_pressed("right"):
			map_scroll_velocity.x =-SCROLL_V
		elif Input.is_action_pressed("left") or Input.is_action_pressed("ui_left"):
			map_scroll_velocity.x = SCROLL_V
		elif Input.is_action_pressed("ui_up"):
			map_scroll_velocity.y = SCROLL_V
		elif Input.is_action_pressed("down"):
			map_scroll_velocity.y = -SCROLL_V

		if (Input.is_action_just_released("right")
				or Input.is_action_just_released("left")):
			map_scroll_velocity.x = 0
		elif (Input.is_action_just_released("down")
				or Input.is_action_just_released("ui_up")):
			map_scroll_velocity.y = 0


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
	inventory.visible = true
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


func _input(event: InputEvent) -> void:
	if (not map_selected and map.has_focus()
			and event.is_action_pressed("ui_accept")):
		select_map()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		unpause()

	if map_selected:
		if Input.is_action_pressed("zoom_in"):
			get_viewport().set_input_as_handled()
			zoom()
		elif Input.is_action_pressed("zoom_out"):
			get_viewport().set_input_as_handled()
			zoom(false)

	if not map_selected and not inventory.selected and event.is_action_pressed("ui_cancel"):
		unpause()


func select_map() -> void:
	if not map_selected:
		inventory_label.visible = false
		inventory.visible = false
		map_label.visible = false
		system_menu_button.visible = false
		back_button.visible = false

		Audio.play_ui_audio(Audio.ui_focus_audio)
		await get_tree().process_frame
		map.grab_focus()

		map_selected = true
		map_overlay.visible = false
		debug_pivot_offset_marker.visible = true

		# center fullscreen map on centered on player indicator
		map.clip_contents = false
		map.position = (-%PlayerIndicator.position / map.scale) + HALF_SCREEN
		map_nodes.position = Vector2.ZERO
		# initialize map pivot offset position
		debug_pivot_offset_marker.position = %PlayerIndicator.position
		map.pivot_offset = %PlayerIndicator.position

		MessageBus.map_selected.emit(true)


func unselect_map() -> void:
	if map_selected:
		Audio.play_ui_audio(Audio.ui_cancel_audio)
		inventory.visible = true
		inventory_label.visible = true
		map_label.visible = true
		system_menu_button.visible = true
		back_button.visible = true

		# reset default values
		map_selected = false
		map.scale = Vector2.ONE
		map.pivot_offset = Vector2.ZERO
		map_scroll_velocity = Vector2.ZERO
		%PlayerIndicator.scale = Vector2.ONE
		debug_pivot_offset_marker.scale = Vector2.ONE
		map_overlay.visible = true
		map.clip_contents = true
		map.position = initial_map_pos
		debug_pivot_offset_marker.visible = false
		map_nodes.position = ((-%PlayerIndicator.position / map.scale)
				+ HALF_SCREEN - Vector2(60, initial_map_pos.y))

		MessageBus.map_selected.emit(false)


func zoom(zoom_in := true) -> void:
	# TODO pivot on the center of the visible map is still buggy
	if zoom_in and map.scale.y < 16:
		map.scale *= 2
		map.pivot_offset = debug_pivot_offset_marker.position

	elif not zoom_in and map.scale.y > 1 / 2.0:
		map.scale /= 2
		map.pivot_offset = debug_pivot_offset_marker.position

	%PlayerIndicator.scale = Vector2.ONE / map.scale
	debug_pivot_offset_marker.scale = Vector2.ONE / map.scale


func on_music_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)
	SaveManager.save_config()


func on_sfx_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(3, value)
	Audio.play_sound(Audio.bugsplat, player.global_position)
	SaveManager.save_config()


func on_ui_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(4, value)
	Audio.play_ui_audio(Audio.bugsplat)
	SaveManager.save_config()


func unpause() -> void:
	get_viewport().set_input_as_handled()
	get_tree().paused = false
	self.queue_free.call_deferred()
