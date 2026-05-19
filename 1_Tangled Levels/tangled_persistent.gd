extends Node2D

var scroll_scale_set := false

@onready var bg_parallax: Parallax2D = $BackgroundVerticalParallax
@onready var bg_texture: TextureRect = $BackgroundVerticalParallax/BackgroundTexture

func _ready() -> void:
	while not scroll_scale_set:
		await get_tree().process_frame
		scroll_scale_set = set_background_scroll_y()


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
