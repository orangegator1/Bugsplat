extends Node2D

# level 1
var current_level := "uid://b5tobrceh3joe"
var level: Node2D
var scroll_scale_set := false
var player

@onready var bg_parallax: Parallax2D = $BackgroundVerticalParallax
@onready var bg_texture: TextureRect = $BackgroundVerticalParallax/BackgroundTexture

func _ready() -> void:
	SceneManager.new_scene_ready.connect(on_new_scene_ready)
	# level load wasn't working without waiting a frame
	await get_tree().process_frame

	level = load(current_level).instantiate()
	get_tree().root.add_child(level)


func _process(_delta: float) -> void:
	if not scroll_scale_set:
		scroll_scale_set = set_background_scroll_y()


func load_scene(new_level: String) -> void:
	if not new_level == current_level:
		# allow current level to be unloaded so that correct level_transition
		# position can be identified to place the player
		level.position = Vector2.ZERO
		SceneManager.level_offset = level.position
		level.queue_free.call_deferred()
		await get_tree().process_frame

		current_level = new_level
		level = load(current_level).instantiate()
		get_tree().root.add_child(level)


func on_new_scene_ready(_target_name: String, offset: Vector2) -> void:
	# shift new level to match exit pos of old level to maintain parallax scroll
	# need to wait exactly two frames and then incoming position
	# will have been set by the level_transition node
	if SceneManager.shifting_incoming_level:
		await get_tree().process_frame
		await get_tree().process_frame
		level.position = (SceneManager.outgoing_position
				- SceneManager.incoming_position)
		SceneManager.level_offset = level.position
		if not player:
			player = await SceneManager.get_player()
		if (SceneManager.transition_direction == SceneManager.SIDE.TOP
				or SceneManager.transition_direction == SceneManager.SIDE.BOTTOM):
			player.global_position -= Vector2(offset.x, 0)
		else:
			player.global_position -= Vector2(0, offset.y)
		print("")


func set_background_scroll_y() -> bool:
	if not bg_parallax or not PlatformManager.layer:
		return false
	var range_y = PlatformManager.get_vertical_bounds(PlatformManager.layer)
	var bot = float(range_y[0])
	var top = float(range_y[1])
	var texture_h = bg_texture.size.y
	var screen_h = GameManager.viewport_size.y
	var half_screen = screen_h / 2.0

	var cam_bot_limit = bot - half_screen
	var cam_top_limit = top
	var max_camera_travel = cam_bot_limit - cam_top_limit

	# scroll scale is a ratio of bg texture height over height of the level
	bg_parallax.scroll_scale.y = (texture_h - screen_h) / max_camera_travel

	# ensure we start at the bottom of the texture
	bg_parallax.scroll_offset.y = -215
	var _target_tex_top = bot - texture_h
	var _cam_limit_bottom = bot - (screen_h / 2.0)

	#var offset = top - ((top - half_screen) * bg_parallax.scroll_scale.y)
	# (bot - texture_h) - ((bot - half_screen) * bg_parallax.scroll_scale.y)
	#bg_parallax.scroll_offset.y = offset

	print("bot: %s, top: %s, height: %s
	bg_parallax.position: %s
	scroll_scale.y: %s, scroll_offset.y: %s"
			% [bot, top, bot-top, bg_parallax.position,
			bg_parallax.scroll_scale.y, bg_parallax.scroll_offset.y])
	print("get_screen_offset(): %s" % [bg_parallax.get_screen_offset()])
	return true
