@tool
@icon("uid://xarc5lty5hwy")

class_name LevelTransition extends Node2D


@export_range(2, 8, 1, "or_greater") var size = 2 :
	set(value):
		size = value
		apply_area_settings()
@export var location: SceneManager.SIDE = SceneManager.SIDE.RIGHT :
	set(value):
		location = value
		apply_area_settings()
@export_file("*.tscn") var target_level = ""
@export var target_area_name = "LevelTransition"

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	apply_area_settings()
	SceneManager.new_scene_ready.connect(on_new_scene_ready)
	SceneManager.load_scene_finished.connect(on_load_scene_finished)


func _on_player_entered(n: Node2D) -> void:
	SceneManager.transition_scene(target_level, target_area_name,
			get_offset(n), get_transition_direction(), true)
	SceneManager.outgoing_position = global_position


func on_new_scene_ready(target_name: String, offset: Vector2) -> void:
	# set position to place either scene or player at
	if target_name == name:
		if SceneManager.shifting_incoming_level:
			SceneManager.incoming_position = global_position + offset
			SceneManager.offset = offset
		else:
			# for editor level testing with F6
			var player = await SceneManager.get_player()
			player.global_position = global_position + offset


func on_load_scene_finished() -> void:
	area_2d.monitoring = false
	# if reloading a save in the current level, dont reconnect
	if not area_2d.body_entered.is_connected(_on_player_entered):
		area_2d.body_entered.connect(_on_player_entered)
	# wait until things are settled to monitor for player entering
	await get_tree().physics_frame
	await get_tree().physics_frame
	area_2d.monitoring = true


func apply_area_settings() -> void:
	area_2d = get_node_or_null("Area2D")
	if not area_2d:
		return

	if location == SceneManager.SIDE.TOP or location == SceneManager.SIDE.BOTTOM:
		area_2d.scale.x = size
		if location == SceneManager.SIDE.TOP:
			area_2d.scale.y = 1
		else:
			area_2d.scale.y = -1
	else:
		area_2d.scale.y = size
		if location == SceneManager.SIDE.RIGHT:
			area_2d.scale.x = 1
		else:
			area_2d.scale.x = -1


func get_offset(player: Node2D) -> Vector2:
	var offset = Vector2.ZERO
	var player_pos := player.global_position
	if location == SceneManager.SIDE.TOP or location == SceneManager.SIDE.BOTTOM:
		offset.x = player_pos.x - global_position.x
		if location == SceneManager.SIDE.TOP:
			offset.y = -2
		else:
			offset.y = player.height + 2
	else:
		offset.y = player_pos.y - global_position.y
		offset.x = area_2d.scale.x * 16
	return offset


func get_transition_direction() -> String:
	# both nodes hold identical enums
	SceneManager.transition_direction = location
	match location:
		SceneManager.SIDE.LEFT:
			return "left"
		SceneManager.SIDE.RIGHT:
			return "right"
		SceneManager.SIDE.TOP:
			return "up"
		_:
			return "down"
