class_name Player extends CharacterBody2D

@export var speed: float = 150.0
@export var jump_velocity: float = -300.0
@export var max_health := 3

signal standing_on_new_growable_layer(layer: TileMapLayer)
signal health_changed(value: int)

var height = 32
var width = 11
var ledge_climb_duration = 0.5
var push_force := 80.0
var health: int
var direction: float
var layer_underfoot: TileMapLayer
var last_y_veloc: float
var climb_timer: SceneTreeTimer
var input_dir
var ledge_grab_dir: int
var pool: Array[GPUParticles2D]
var index := 0

var is_on_ledge := false
var is_on_small_ledge := false
var is_in_y_tween := false
var is_in_x_tween := false
var input_locked := false
# true until next hitting the ground
var is_jumping := false
# true until two frame jump animation is done playing
var jumped := false
var ledge_climbing := false
var started_climb := false
var climbing_less_sloped := false
var climbing_most_sloped := false
var climbing_sloped := false
var falling_fast := false
var background_set_up := false
var resetting := false

@onready var animated_sprites: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var ledge_grab_miss: RayCast2D = $ledgeGrabMiss
@onready var ledge_grab_hit: RayCast2D = $ledgeGrabHit
@onready var freefall_timer: Timer = $freefallTimer
@onready var ledge_climb_lockout: Timer = $ledgeClimbLockout
@onready var camera_2d: Camera2D = $Camera2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sound_effect_player: AnimationPlayer = $SoundEffectPlayer
@onready var debug_label: Label = $DebugLabel
@onready var dirt_falling: GPUParticles2D = $Particles/DirtFalling
@onready var dirt_falling_2: GPUParticles2D = $Particles/DirtFalling2
@onready var dirt_falling_3: GPUParticles2D = $Particles/DirtFalling3

var bg_parallax: Parallax2D
var ground: TileMapLayer
var background_texture: TextureRect
#@onready var bg_parallax: Parallax2D = $"../Level/BackgroundVerticalParallax"
#@onready var background_texture: TextureRect = $"../BackgroundVerticalParallax/BackgroundTexture"

func _ready() -> void:
	# delete duplicate players
	if not get_tree().get_first_node_in_group("Player"):
		add_to_group("Player")
	if get_tree().get_first_node_in_group("Player") != self:
		await get_tree().process_frame
		self.queue_free()

	# populate player particle pools
	pool = [dirt_falling, dirt_falling_2, dirt_falling_3,]

	# reparent player node to root

	# need to reorganize how nodes are found by the player
	# moving the player in the tree is breaking all references to other objects
	if not get_parent() == get_tree().root:
		self.reparent.call_deferred(get_tree().root)

	(animated_sprites.get_sprite_frames().
			set_animation_speed("ledge_climb", 13 / ledge_climb_duration))
	PlatformManager.connect_player_to_platform_manager(self)
	speed = 150.0
	health = max_health
	health_changed.emit(health)


func _process(_delta: float) -> void:
	if not background_set_up:
		background_set_up = set_background_scroll_y()

	update_label("health:" + str(health))


func _physics_process(delta: float) -> void:
	handle_sprite()
	# fixes camera stutters and unpredictable position
	# (due to collisions during player position tweens?)
	if is_in_x_tween or is_in_y_tween or input_locked:
		return

	for i in get_slide_collision_count():
		get_layer_under_feet(get_slide_collision(i))
		push_objects(get_slide_collision(i))

	handle_movement(delta)

	# Coyote time
	var was_on_floor = is_on_floor()

	move_and_slide()

	# Coyote time
	if was_on_floor and not is_on_floor() and not is_jumping:
		coyote_timer.start()

	handle_input()


func handle_input() -> void:
	grow_listener()
	# other input listeners here


func grow_listener() -> void:
	var grew = false
	if Input.is_action_just_pressed("interact") and is_on_floor():
		if layer_underfoot:
			grew = await PlatformManager.grow(layer_underfoot,
				layer_underfoot.atlas_id,
				layer_underfoot.filler_tile, self)
	if grew:
		sound_effect_player.play_sound(SFX.grow_up, global_position)
		#var time = sound_effect_player.current_animation_length
		#if not Music.fading:
			#Music.fade_music_out_in(time + 1)


func handle_movement(delta: float) -> void:
	# Add the gravity.
	if not (is_on_floor() or is_in_y_tween or is_on_ledge):
		velocity += get_gravity() * delta
		falling_fast = velocity.y > 650
		# don't play falling animation for small drops
		if last_y_veloc <= 0 and velocity.y > 0 and not is_jumping:
			freefall_timer.start()
		last_y_veloc = velocity.y
	if is_on_floor() and falling_fast:
		falling_fast = false
		input_locked = true
		velocity = Vector2.ZERO
		animation_player.play("heavy_landing")
		sound_effect_player.play_sound(SFX.heavy_landing, global_position)
		set_health_check_reset(-1)
		var t = animation_player.get_animation("heavy_landing").length
		var lock_out_timer = get_tree().create_timer(t)
		await lock_out_timer.timeout
		input_locked = false


	# Handle jump
	if Input.is_action_just_pressed("jump") and (is_on_floor() or
		not coyote_timer.is_stopped()):
		velocity.y = jump_velocity
		is_jumping = true
		jumped = true
	elif is_on_floor():
		is_jumping = false


	# Get the input direction and handle horiz. movement
	input_dir = Input.get_axis("move_left", "move_right")

	# when loading in there is no friction avail. until hitting the ground
	if (	layer_underfoot and not is_on_ledge
			and not is_in_y_tween and not is_in_x_tween):
		# accelerate
		if input_dir:
			# make switching directions feel more responsive to input
			if sign(velocity.x) != sign(input_dir):
				velocity.x = 0
			velocity.x = move_toward(velocity.x, input_dir * speed,
				layer_underfoot.friction * delta)
		# decelerate
		else:
			velocity.x = move_toward(velocity.x, 0,
				layer_underfoot.friction * delta * 2)

	if not is_on_ledge:
		handle_ledge_grab()
		# have to input horiz. into the ledge to grab, don't want to
		# instantly trigger the ledge action (climb up) signalled by that input
		ledge_climb_lockout.start()

	if is_on_ledge:
		handle_ledge_input()


func handle_ledge_grab() -> void:
	# player should be in the air, moving downwards, horiz. input into the wall
	if is_on_floor() or input_dir == 0 or velocity.y <= 0:
		return

	# flip raycasts if needed
	if sign(ledge_grab_hit.target_position.x) != sign(input_dir):
		ledge_grab_hit.target_position.x *= -1
	if sign(ledge_grab_miss.target_position.x) != sign(input_dir):
		ledge_grab_miss.target_position.x *= -1
	# no collision on top raycast signals empty space above the ledge
	if (not ledge_grab_miss.is_colliding()) and ledge_grab_hit.is_colliding():
		# calculate the position to snap the player to
		var layer = ledge_grab_hit.get_collider()
		if not layer is TileMapLayer:
			return
		var normal = ledge_grab_hit.get_collision_normal()
		ledge_grab_dir = sign(ledge_grab_hit.get_collision_point().x - global_position.x)

		# check if there is a slope above the ledge we are grabbing
		var tile_size = layer.tile_size
		var pos = ledge_grab_hit.get_collision_point()
		var tile_above_pos = pos + Vector2(ledge_grab_dir, 0)
		tile_above_pos = PlatformManager.center_of_tile_at(tile_above_pos, layer)
		tile_above_pos += Vector2(0, -tile_size)
		var collider_above = PlatformManager.collider_at(tile_above_pos)

		# different animation for grabbing a 1-tile tall ledge
		var tile_below_pos = tile_above_pos + Vector2(0, 3 * tile_size)
		is_on_small_ledge = not PlatformManager.collider_at(tile_below_pos)

		climbing_sloped = normal.y != 0 or collider_above
		is_on_ledge = true
		velocity = Vector2.ZERO

		# move the tile detection position into the tile by 1 pixel
		var tmp = pos + Vector2(ledge_grab_dir, 0)
		pos = PlatformManager.center_of_tile_at(tmp, layer)
		# get top corner position of tile
		pos += Vector2(tile_size / 2 * -ledge_grab_dir, tile_size / -2)
		# offsets for the current player collision rect
		# and account for the fact that player position is at their feet
		pos += Vector2(collider.shape.size.x / 2 * -ledge_grab_dir, height - 8)

		# if initial raycast collision was on a slope,
		# shift the tween position down one tile
		if normal.y != 0:
			pos += Vector2(0, tile_size)

		var tween = create_tween()
		tween.tween_property(self, "global_position", pos, 0.05)
		set_tween_flags("xy", tween, ledge_grab_dir)


func handle_ledge_input() -> void:
	# jump up, may not be a necessary mode
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		is_jumping = true
		jumped = true
		is_on_ledge = false
	# drop
	elif Input.is_action_just_pressed("down"):
		velocity.y = jump_velocity * -0.5
		is_on_ledge = false
	#climb up or ledge jump
	elif input_dir and ledge_climb_lockout.is_stopped():
		# jump away, input away from the wall
		if ledge_grab_dir != input_dir:
			velocity = Vector2(-jump_velocity * input_dir * 0.75,
				jump_velocity * 0.75)
			is_jumping = true
			jumped = true
			is_on_ledge = false
		# climb up, input into the wall
		elif not is_in_y_tween:
			# offsets specifically for the idle sprite
			var tile_w = layer_underfoot.tile_size

			# set flags that determine tween position for ledge climb
			# when hanging from ledge, top raycast hits sloped tiles above
			if ledge_grab_miss.is_colliding():
				var normal = ledge_grab_miss.get_collision_normal()
				var normal_rads  = abs(normal).angle()
				climbing_most_sloped = abs(angle_difference(normal_rads,
						PI / 4.0)) < 0.1
				climbing_less_sloped = abs(angle_difference(normal_rads,
						PI * 0.35)) < 0.1

			var snap_pos := global_position + Vector2(0, -height + 9)
			snap_pos += Vector2(tile_w * ledge_grab_dir, 0)
			if climbing_most_sloped:
				snap_pos += Vector2(tile_w / 2 * -ledge_grab_dir, -tile_w)
				climbing_most_sloped = false;
			elif climbing_less_sloped:
				snap_pos += Vector2(tile_w / 4 * -ledge_grab_dir, -tile_w / 2)
				climbing_less_sloped = false;

			# check for tile collisions at the new position
			var player_col_check_bot = snap_pos + Vector2(0, -tile_w / 2)
			var player_col_check_top = snap_pos + Vector2(0, -tile_w * 1.5)
			var collider_bot = PlatformManager \
					.collider_at(player_col_check_bot)
			var vacant_bot = climbing_sloped or not collider_bot
			climbing_sloped = false;
			var vacant_top = not PlatformManager \
					.collider_at(player_col_check_top)
			if vacant_bot and vacant_top:
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_CIRC)
				tween.tween_property(self, "global_position", snap_pos,
					ledge_climb_duration)
				sound_effect_player.play_sound(SFX.ledge_climb,
						global_position)

				set_tween_flags("xy", tween, ledge_grab_dir)
				ledge_climbing = true
				started_climb = true
				climb_timer = get_tree().create_timer(ledge_climb_duration)
				is_on_ledge = false

				await climb_timer.timeout
				ledge_climbing = false
	# sweet spot ledge jump, is 33% faster
	elif (input_dir and
			ledge_climb_lockout.time_left < ledge_climb_lockout.wait_time):
		if ledge_grab_dir != input_dir:
			velocity = Vector2(jump_velocity * ledge_grab_dir,
					jump_velocity)
			sound_effect_player.play_sound(SFX.ledge_jump, global_position)
			is_jumping = true
			jumped = true
			is_on_ledge = false
	else:
		velocity = Vector2.ZERO


func get_ledge_climb_end_pos() -> Vector2:
	return Vector2.ZERO


func handle_sprite() -> void:
	# fix for ledge sprite that would fail to flip if
	# inputting into a tile and velocity x is not changing
	if is_on_ledge:
		animated_sprites.flip_h = ledge_grab_dir == -1
	elif velocity.x > 0:
		animated_sprites.flip_h = false
	elif velocity.x < 0:
		animated_sprites.flip_h = true

	if health <= 0:
		if not animated_sprites.animation == "reset" and not resetting:
			resetting = true
			animated_sprites.play("reset")
	elif animation_player.is_playing():
		pass
	elif is_on_ledge:
		if is_on_small_ledge:
			animated_sprites.play("ledge_hang_small")
		else:
			animated_sprites.play("ledge_hang")
	elif ledge_climbing:
		if started_climb and climb_timer.time_left > 0:
			started_climb = false
			# animation is 16px taller than base 48px, and is centered
			animated_sprites.position.y -= 8

			var particles = pool[index]
			index = (index + 1) % pool.size()
			particles.modulate.a = 1.0
			particles.process_material.direction.x = -ledge_grab_dir
			var offset = particles.process_material.emission_shape_offset.x
			offset *= ledge_grab_dir
			particles.process_material.emission_shape_offset.x = offset
			particles.emitting = true

			await climb_timer.timeout
			animated_sprites.position.y += 8
		animated_sprites.play("ledge_climb")
	elif is_on_floor():
		if velocity.x != 0 or is_in_x_tween:
			animated_sprites.play("run")
		else:
			animated_sprites.play("idle")
	elif jumped:
		animated_sprites.play("jump")
		await animated_sprites.animation_finished
		jumped = false
	elif is_jumping or (!is_jumping and freefall_timer.is_stopped()):
		animated_sprites.play("falling")
	elif climb_timer:
		animated_sprites.play("idle")
	else:
		animated_sprites.play("idle")


func push_objects(collision: KinematicCollision2D) -> void:
	if collision.get_collider() is RigidBody2D:
		collision.get_collider().apply_central_impulse(-collision.get_normal() * push_force)


func get_layer_under_feet(collision: KinematicCollision2D) -> void:
	# Check all collisions from the last movement
	var collided := collision.get_collider()
	var normal = collision.get_normal()

	# Check if the thing we hit is growable and below the player
	if (collided is TileMapLayer and normal.y < 0 and not layer_underfoot == collided):
		layer_underfoot = collided
		standing_on_new_growable_layer.emit(collided)

		# disable growing on certain terrain?
		#if (collided.is_in_group("growable_tiles")


func set_tween_flags(mode: String, tween: Tween, dir := 0) -> void:
	# print linked error to output
	if (mode.contains("x") and is_in_x_tween
			or mode.contains("y") and is_in_y_tween):
		CustomErrors.push_error_custom("Tween flag(s) are already true.",1)

	is_in_x_tween = mode.contains("x")
	is_in_y_tween = mode.contains("y")
	if mode == "x":
		if dir == 1 and animated_sprites.flip_h == true:
			animated_sprites.flip_h = false
		elif dir == -1 and animated_sprites.flip_h == false:
			animated_sprites.flip_h = true
	await tween.finished

	if mode.contains("x"):
		is_in_x_tween = false
	if mode.contains("y"):
		is_in_y_tween = false
	freefall_timer.start()


func set_background_scroll_y() -> bool:
	if not layer_underfoot or not bg_parallax or not camera_2d:
		return false
	var range_y = PlatformManager.get_vertical_bounds(layer_underfoot)
	var bot = float(range_y[0])
	var top = float(range_y[1])
	#var level_height = abs(bot - top)
	var texture_h = background_texture.size.y
	var screen_h = GameManager.viewport_size.y
	var half_screen = screen_h / 2.0
	camera_2d.limit_bottom = int(bot)
	camera_2d.limit_top = int(top - half_screen)

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
	camera_2d.position: %s
	scroll_scale.y: %s, scroll_offset.y: %s"
			% [bot, top, bot-top, bg_parallax.position, camera_2d.position,
			bg_parallax.scroll_scale.y, bg_parallax.scroll_offset.y])
	print("get_screen_offset(): %s" % [bg_parallax.get_screen_offset()])
	return true


func set_health_check_reset(amount: int = 0) -> void:
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health)
	if health == 0:
		SceneManager.reset()


func update_label(text: String) -> void:
	debug_label.text = text
