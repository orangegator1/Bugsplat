class_name Player extends CharacterBody2D

@export var jump_velocity: float = -300.0
@export var max_health := 3

signal health_changed(value: int)

var height = 32
var width = 11
var speed := 150.0
var ledge_climb_duration = 0.4
var push_force := 80.0
var friction := 500.0
var gravity_mod := 1.0
var fall_gravity := 1.165
var jump_buffer_time := 0.15
var jump_buffer_timer: float = 0
var health: int
var direction: float
var last_y_veloc: float
var climb_timer: SceneTreeTimer
var input_dir: float
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
var camera_set_up := false
var resetting := false

enum a {
	IDLE, RUN, JUMP, FALLING, LEDGE_CLIMB,
	LEDGE_HANG, LEDGE_HANG_SMALL, RESET, LANDING,
}
var anims: Array[String] = [
	"idle", "run", "jump", "falling", "ledge_climb",
	"ledge_hang", "ledge_hang_small", "reset", "landing",
]
var equipped_cosmetics: Array[String] = [ "propeller_hat", ]
var owned_cosmetics: Array[String] = [ "propeller_hat", "metroidvania_hair" ]
var items: Array[String] = []
var inventory = {
	"cosmetics" : owned_cosmetics,
	"items" : items
	}

@onready var animated_sprites: AnimatedSprite2D = $Node2D/AnimatedSprite2D
@onready var cosmetics: Node2D = $Node2D/Cosmetics
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var ledge_grab_miss: RayCast2D = $ledgeGrabMiss
@onready var ledge_grab_hit: RayCast2D = $ledgeGrabHit
@onready var ledge_climb_lockout: Timer = $ledgeClimbLockout
@onready var camera_2d: Camera2D = $Camera2D
@onready var debug_label: Label = $DebugLabel
@onready var dirt_falling: GPUParticles2D = $Particles/DirtFalling
@onready var dirt_falling_2: GPUParticles2D = $Particles/DirtFalling2
@onready var dirt_falling_3: GPUParticles2D = $Particles/DirtFalling3


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
	if not get_parent() == get_tree().root:
		self.reparent.call_deferred(get_tree().root)

	# turn on cosmetics if any
	for c in equipped_cosmetics:
		cosmetics.get_node_or_null(c).visible = true

	health = max_health
	health_changed.emit(health)

	MessageBus.player_health_changed.connect(set_health_check_reset)


func _process(delta: float) -> void:
	if not camera_set_up:
		camera_set_up = set_camera_limits()

	jump_buffer_timer -= delta


func _physics_process(delta: float) -> void:
	handle_sprite()
	# fixes camera stutters and unpredictable position
	# (due to collisions during player position tweens?)
	if is_in_x_tween or is_in_y_tween or input_locked:
		return

	for i in get_slide_collision_count():
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


func grow_listener() -> void:
	var grew = false
	if Input.is_action_just_pressed("interact") and is_on_floor():
		if PlatformManager.layer:
			grew = await PlatformManager.grow(self)
	if grew:
		Audio.play_sound(Audio.grow_up, global_position)


func handle_movement(delta: float) -> void:
	# Add the gravity.
	if velocity.y > 0:
		gravity_mod = fall_gravity
	else:
		gravity_mod = 1.0
	if not (is_on_floor() or is_in_y_tween or is_on_ledge):
		velocity += get_gravity() * delta * gravity_mod
		falling_fast = velocity.y > 650

		last_y_veloc = velocity.y

	# take damage when falling too fast
	if is_on_floor() and falling_fast:
		falling_fast = false
		input_locked = true
		# zero x velocity during animation
		velocity = Vector2.ZERO
		animated_sprites.play(anims[a.LANDING])
		Audio.play_sound(Audio.heavy_landing, global_position)
		set_health_check_reset(-1)

		var cosmetic: AnimatedSprite2D
		for c in equipped_cosmetics:
			cosmetic = cosmetics.get_node_or_null(c)
			if cosmetic:
				cosmetic.flip_h = animated_sprites.flip_h
				cosmetic.play(anims[a.LANDING])

		await animated_sprites.animation_finished
		animated_sprites.play(anims[a.IDLE])
		if cosmetic:
			cosmetic.play(anims[a.IDLE])
		await get_tree().create_timer(0.1).timeout
		input_locked = false


	# Handle jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or not coyote_timer.is_stopped():
			velocity.y = jump_velocity
			is_jumping = true
			jumped = true
		else:
			jump_buffer_timer = jump_buffer_time
	elif is_on_floor() and jump_buffer_timer > 0:
		velocity.y = jump_velocity

		# if the jump was buffered, need to check if the jump button has already
		# been released, to get a variable jump height and decelleration
		if not Input.is_action_pressed("jump"):
			if velocity.y < -120:
				velocity.y *= 0.7
			else:
				velocity.y *= 0.5

		is_jumping = true
		jumped = true
	elif Input.is_action_just_released("jump"):
		if velocity.y < -120:
			velocity.y *= 0.7
		else:
			velocity.y *= 0.5
	elif is_on_floor() or is_on_ledge:

		is_jumping = false


	# Get the input direction and handle horiz. movement mapped to -1, 0, or 1
	input_dir = Input.get_axis("left", "right")
	# deadzone for busted controllers with bad joysticks
	if abs(input_dir) < 0.1:
		input_dir = 0.0
	if not input_dir == 0:
		input_dir = -1 if (input_dir < 0) else 1

	# when loading in there is no friction avail. until hitting the ground
	if (not is_on_ledge	and not is_in_y_tween and not is_in_x_tween):
		if PlatformManager.layer and PlatformManager.layer is GrowableTileset:
				friction = PlatformManager.layer.friction
		# accelerate
		if input_dir:
			# make switching directions feel more responsive to input
			if sign(velocity.x) != sign(input_dir):
				velocity.x = 0
			velocity.x = move_toward(velocity.x, input_dir * speed,
				friction * delta)
		# decelerate
		else:
			velocity.x = move_toward(velocity.x, 0,
				friction * delta * 2)

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
		var tween_pos = get_ledge_snap_pos()
		var tween = create_tween()
		tween.tween_property(self, "global_position", tween_pos, 0.05)
		set_tween_flags("xy", tween, ledge_grab_dir)
		is_on_ledge = true
		falling_fast = false


func handle_ledge_input() -> void:
	# jump up
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
			var tile_w = PlatformManager.layer.tile_size

			# set flags that determine tween position for ledge climb
			# when hanging from ledge, top raycast hits sloped tiles above
			if ledge_grab_miss.is_colliding():
				var normal = ledge_grab_miss.get_collision_normal()
				var normal_rads  = abs(normal).angle()
				# if hit a full slope ~(45 degrees)
				climbing_most_sloped = abs(angle_difference(normal_rads,
						PI / 4.0)) < 0.1
				# if hit a half slope (~23 degrees)
				climbing_less_sloped = abs(normal_rads - (PI * 0.35)) < 0.1

			var snap_pos := global_position + Vector2(0, -height + 1)
			snap_pos += Vector2(tile_w * ledge_grab_dir, 0)
			if climbing_most_sloped:
				snap_pos += Vector2(tile_w / 2 * -ledge_grab_dir, -tile_w / 2)
				climbing_most_sloped = false;
			elif climbing_less_sloped:
				snap_pos += Vector2(tile_w / 4 * -ledge_grab_dir, -tile_w / 2)
				climbing_less_sloped = false;

			# check for tile collisions at the new position
			var player_col_check_bot = snap_pos + Vector2(0, -tile_w / 2)
			var player_col_check_top = snap_pos + Vector2(0, -tile_w * 1.5)
			var collider_bot = PlatformManager.collider_at(player_col_check_bot)
			var vacant_bot = climbing_sloped or not collider_bot
			climbing_sloped = false;
			var vacant_top = not PlatformManager.collider_at(player_col_check_top)
			if vacant_bot and vacant_top:
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_CIRC)
				tween.tween_property(self, "global_position", snap_pos,
					ledge_climb_duration)
				Audio.play_sound(Audio.ledge_climb,
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
			Audio.play_sound(Audio.ledge_jump, global_position)
			is_jumping = true
			jumped = true
			is_on_ledge = false
	else:
		velocity = Vector2.ZERO


func get_ledge_snap_pos() -> Vector2:
	# calculate the position to snap the player to
	var layer = ledge_grab_hit.get_collider()
	if not layer is TileMapLayer:
		CustomErrors.push_error_custom("ledge_grab_hit reported hitting
				something not a TileMapLayer.",0)
		return Vector2.ZERO
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
	velocity = Vector2.ZERO

	# move the tile detection position into the tile by 1 pixel
	var tmp = pos + Vector2(ledge_grab_dir, 0)
	pos = PlatformManager.center_of_tile_at(tmp, layer)
	# get top corner position of tile
	pos += Vector2(tile_size / 2 * -ledge_grab_dir, tile_size / -2)
	# offsets for the current player collision rect
	# position is at their feet and centered
	pos += Vector2(5 * -ledge_grab_dir, height - 1)

	# if initial raycast collision was on a slope,
	# shift the tween position down one tile
	if normal.y != 0:
		pos += Vector2(0, tile_size)

	return pos


func handle_sprite() -> void:
	# fix for ledge sprite that would fail to flip if
	# inputting towards a tile and velocity x was not changing
	if is_on_ledge:
		animated_sprites.flip_h = ledge_grab_dir == -1
	elif velocity.x > 0:
		animated_sprites.flip_h = false
	elif velocity.x < 0:
		animated_sprites.flip_h = true

	var curr_anim := ""

	if health <= 0:
		if not animated_sprites.animation == anims[a.RESET] and not resetting:
			resetting = true
			curr_anim = anims[a.RESET]
			animated_sprites.play(curr_anim)
	elif input_locked:
		pass
	elif is_on_ledge:
		if is_on_small_ledge:
			curr_anim = anims[a.LEDGE_HANG_SMALL]
			animated_sprites.play(curr_anim)
		else:
			curr_anim = anims[a.LEDGE_HANG]
			animated_sprites.play(curr_anim)
	elif ledge_climbing:
		curr_anim = anims[a.LEDGE_CLIMB]
		animated_sprites.play(curr_anim)
		if started_climb and climb_timer.time_left > 0:

			#Engine.time_scale = 0.1

			started_climb = false
			# animation is 16px taller than base 48px, and is centered
			animated_sprites.offset.y -= 8
			cosmetics.position.y -= 8

			var particles = pool[index]
			index = (index + 1) % pool.size()
			particles.modulate.a = 1.0
			particles.process_material.direction.x = -ledge_grab_dir
			var offset = particles.process_material.emission_shape_offset.x
			offset *= ledge_grab_dir
			particles.process_material.emission_shape_offset.x = offset
			particles.emitting = true

			await climb_timer.timeout
			curr_anim = anims[a.IDLE]
			animated_sprites.play(curr_anim)
			animated_sprites.offset.y += 8
			cosmetics.position.y += 8

			Engine.time_scale = 1.0

	elif is_on_floor():
		if velocity.x != 0 or is_in_x_tween:
			curr_anim = anims[a.RUN]
			animated_sprites.play(curr_anim)
		else:
			curr_anim = anims[a.IDLE]
			animated_sprites.play(curr_anim)
	elif jumped:
		curr_anim = anims[a.JUMP]
		animated_sprites.play(curr_anim)
		await animated_sprites.animation_finished
		jumped = false
	elif (not ledge_climbing and is_jumping) or velocity.y > 0:
		curr_anim = anims[a.FALLING]
		animated_sprites.play(curr_anim)
	else:
		curr_anim = anims[a.IDLE]
		animated_sprites.play(curr_anim)

	for c in equipped_cosmetics:
		var cosmetic = cosmetics.get_node_or_null(c)
		if cosmetic:
			cosmetic.play(curr_anim)
			cosmetic.flip_h = animated_sprites.flip_h


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		MessageBus.player_interacted.emit(self)
	elif event.is_action_pressed("pause"):
		get_tree().paused = true
		var pause_menu: PauseMenu = load("res://pause_menu/pause_menu.tscn").instantiate()
		add_child(pause_menu)
		return


func push_objects(collision: KinematicCollision2D) -> void:
	if collision.get_collider() is RigidBody2D:
		collision.get_collider().apply_central_impulse(-collision.get_normal() * push_force)


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


func set_camera_limits() -> bool:
	if not camera_2d:
		return false
	var range_y = PlatformManager.get_vertical_bounds()
	var bot = float(range_y[0])
	var top = float(range_y[1])
	var screen_h = GameManager.viewport_size.y
	var half_screen = screen_h / 2.0
	camera_2d.limit_bottom = int(bot + SceneManager.level_offset.y)
	camera_2d.limit_top = int(top - half_screen + SceneManager.level_offset.y)
	return true


func set_health_check_reset(amount: int = 0, incrementing = true) -> void:
	if incrementing:
		health = clampi(health + amount, 0, max_health)
	else:
		health = clampi(amount, 0, max_health)
	health_changed.emit(health)
	if health == 0:
		SceneManager.reset()


func reset_flags() -> void:
	velocity = Vector2.ZERO
	is_on_ledge = false
	is_jumping = false
	falling_fast = false


func update_label(text: String) -> void:
	debug_label.text = text
