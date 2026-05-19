extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished
signal scene_entered(uid: String)

# level 1
var current_scene = "uid://b5tobrceh3joe"
const FADE_DURATION = 0.25
var outgoing_position: Vector2
var incoming_position: Vector2
var level_offset: Vector2
enum SIDE { TOP, RIGHT, BOTTOM, LEFT }
var transition_direction: SIDE
var shifting_incoming_level := false

@onready var fade: Control = $Fade

func _ready() -> void:
	await get_player()
	warm_particles()

	fade.visible = false

	await get_tree().process_frame
	load_scene_finished.emit()


func transition_scene( new_scene: String,
		target_area: String,
		player_offset: Vector2,
		dir: String,
		shift_incoming_level := false) -> void:

	load_scene_started.emit()
	get_tree().paused = true

	var fade_pos = get_fade_position(dir)
	fade.visible = true
	await fade_screen(fade_pos, Vector2.ZERO)

	shifting_incoming_level = shift_incoming_level
	print("shifting_incoming_level: " + str(shifting_incoming_level))
	var persistent_scene = get_tree().get_first_node_in_group("PersistentScene")
	if persistent_scene:
		await persistent_scene.load_scene(new_scene)
	else:
		get_tree().change_scene_to_file.call_deferred(new_scene)
		await get_tree().scene_changed
	current_scene = ResourceUID.path_to_uid(new_scene)
	scene_entered.emit(current_scene)

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


func get_player() -> Player:
	var player: Player = null
	while not player:
		player = get_tree().get_first_node_in_group("Player")
		await get_tree().process_frame
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
