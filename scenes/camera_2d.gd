extends Camera2D
@onready var player: CharacterBody2D

const INITIAL_OFFSET := Vector2(0, 2.0)
var transitioning := false

# affects camera offset lerp speed
var v = 5.0

# values to modify the camera lerp
var xy: Vector2
var jump_y: float

func _ready() -> void:
	while not player:
		await get_tree().process_frame
		player = get_parent()
	xy = Vector2(32.5 / player.speed, 13.0 / player.speed)
	jump_y = -21.5 / player.speed

	SceneManager.load_scene_started.connect(on_load_scene_started)
	SceneManager.new_scene_ready.connect(on_new_scene_ready)

func _process(delta: float) -> void:
	if not transitioning:
		if player:
			set_pos_to_player()
			set_camera_movement_offset(delta)


func set_pos_to_player() -> void:
	global_position = player.global_position + INITIAL_OFFSET


func set_camera_movement_offset(delta: float) -> void:
	if player.is_on_floor() and abs(player.velocity.x) > 100:
		offset = offset.lerp(player.velocity * xy, delta * v)
	# falling
	elif player.velocity.y > 0:
		offset = offset.lerp(player.velocity * xy, delta * v)
	#jumping
	else:
		offset = offset.lerp(Vector2(player.velocity.x * xy.x,
			player.velocity.y * jump_y), delta * v)


func on_load_scene_started() -> void:
	transitioning = true


func on_new_scene_ready(_target_name: String, _offset: Vector2i) -> void:
	# allow time for level_transition to place the player
	await get_tree().process_frame

	transitioning = false

	set_pos_to_player()
	reset_smoothing()
	reset_smoothing()
