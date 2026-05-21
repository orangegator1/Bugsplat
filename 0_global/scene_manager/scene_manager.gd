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
var current_level := ""
var persistent_scene: Node2D
var level
var initiated_from_pause_menu := false

@onready var fade: Control = $Fade

func _ready() -> void:
	fade.visible = false

	await get_player()
	warm_particles()

	await get_tree().process_frame
	scene_entered.emit(current_scene)
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
	persistent_scene = get_tree().get_first_node_in_group("PersistentScene")
	if persistent_scene:
		load_scene(new_scene)
	else:
		# for testing levels with F6
		shifting_incoming_level = false
		get_tree().change_scene_to_file.call_deferred(new_scene)
		await get_tree().scene_changed
	current_scene = ResourceUID.path_to_uid(new_scene)
	scene_entered.emit(current_scene)

	new_scene_ready.emit(target_area, player_offset)
	on_new_scene_ready(target_area, player_offset)

	# allow time for player and camera to be positioned
	# before showing the new scene
	print("before")
	await get_player()
	print("got player in transition_scene")
	await get_tree().process_frame
	await fade_screen(Vector2.ZERO, -fade_pos)

	get_tree().paused = false
	fade.visible = false
	load_scene_finished.emit()


func transition_scene_to_title( new_scene: String, dir: String) -> void:
	load_scene_started.emit()
	get_tree().paused = true

	var fade_pos = get_fade_position(dir)
	fade.visible = true
	await fade_screen(fade_pos, Vector2.ZERO)

	shifting_incoming_level = false
	if level:
		level.position = Vector2.ZERO
		level_offset = level.position
		current_level = new_scene
		current_scene = ""

	if persistent_scene:
		persistent_scene.queue_free.call_deferred()
		await persistent_scene.tree_exited
		persistent_scene = null

	get_tree().change_scene_to_file.call_deferred(new_scene)
	await get_tree().scene_changed
	scene_entered.emit(current_scene)

	new_scene_ready.emit("LevelTransition", Vector2.ZERO)
	on_new_scene_ready("LevelTransition", Vector2.ZERO)

	# allow time for player and camera to be positioned
	# before showing the new scene
	await get_player()
	await get_tree().process_frame
	await fade_screen(Vector2.ZERO, -fade_pos)

	get_tree().paused = false
	fade.visible = false
	load_scene_finished.emit()



func on_new_scene_ready(_target_name: String, player_offset: Vector2) -> void:
	# shift new level to match exit pos of old level to maintain parallax scroll
	# need to wait exactly two frames and then incoming position
	# will have been set by the LevelTransition node
	if shifting_incoming_level:
		await get_tree().process_frame
		await get_tree().process_frame
		level.position = (outgoing_position - incoming_position)
		level_offset = level.position
		var player = await get_player()
		if (transition_direction == SIDE.TOP or transition_direction == SIDE.BOTTOM):
			player.global_position -= Vector2(player_offset.x, 0)
		else:
			player.global_position -= Vector2(0, player_offset.y)


func load_scene(new_level: String) -> void:
	# return level to origin and reset level_offset
	if level:
		level.position = Vector2.ZERO
		level_offset = level.position

	if not new_level == current_level:
		# allow current level to be unloaded so that correct LevelTransition
		# position can be identified to place the player
		if level:
			level.queue_free.call_deferred()

		# add new level as child of persistent scene
		current_level = new_level
		level = load(current_level).instantiate()
		persistent_scene.add_child(level)


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
