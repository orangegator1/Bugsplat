extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2i)
signal load_scene_finished

const FADE_DURATION = 0.2

@onready var fade: Control = $Fade

func _ready() -> void:
	await get_player()
	warm_particles()

	fade.visible = false

	await get_tree().process_frame
	load_scene_finished.emit()


func transition_scene( new_scene: String,
		target_area: String,
		player_offset: Vector2i,
		dir: String) -> void:

	load_scene_started.emit()
	get_tree().paused = true

	var fade_pos = get_fade_position(dir)
	fade.visible = true
	await fade_screen(fade_pos, Vector2.ZERO)

	get_tree().change_scene_to_file.call_deferred(new_scene)
	await get_tree().scene_changed

	new_scene_ready.emit(target_area, player_offset)

	await fade_screen(Vector2.ZERO, -fade_pos)

	get_tree().paused = false
	fade.visible = false
	load_scene_finished.emit()


func fade_screen(from: Vector2, to: Vector2) -> Signal:
	fade.position = from
	var tween = create_tween()
	tween.tween_property(fade, "position", to, FADE_DURATION)
	return tween.finished


func get_fade_position(dir: String) -> Vector2:
	var fade_pos := Vector2(GameManager.viewport_size) * 2

	match dir:
		"left":
			fade_pos *= Vector2(-1, 0)
		"right":
			fade_pos *= Vector2(1, 0)
		"up":
			fade_pos *= Vector2(0, -1)
		"down":
			fade_pos *= Vector2(0, 1)

	return fade_pos


func get_player() -> CharacterBody2D:
	var player: CharacterBody2D = null
	while not player:
		if is_inside_tree():
			await get_tree().process_frame
		if is_inside_tree():
			player = get_tree().get_first_node_in_group("Player")
	return player


func warm_particles() -> void:
	var particles = get_tree().get_nodes_in_group("warmup_particles")

	for p in particles:
		p.emitting = true
		p.modulate.a = 0.001

	# wait for the engine to send the draw commands to the GPU
	await get_tree().process_frame

	# after compiled and drawn for one frame
	await RenderingServer.frame_post_draw

	for p in particles:
		p.emitting = false
		p.modulate.a = 1.0


func reset() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	player.sound_effect_player.play("bugsplat")
	Engine.time_scale = 0.3
	player.collider.queue_free()
	await get_tree().create_timer(0.8, true, false, true).timeout
	Engine.time_scale = 1
	player.queue_free.call_deferred()
