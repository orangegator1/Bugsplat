extends Node

const SLOTS: Array[String] = ["save_01", "save_02", "save_03", ]

var current_slot: int = 0
var save_data: Dictionary
var discovered_areas: Array = []
var persistent_data: Dictionary

var new_game_scene: String = "uid://b5tobrceh3joe"

func _ready() -> void:
	pass


func create_new_game_save() -> void:
	discovered_areas.append(new_game_scene)
	save_data = {
		"scene_path" : new_game_scene,
		"x" : -1010,
		"y" : 724,
		"health" : 3,
		"max_health" : 3,
		"ability" : false,
		"discovered_areas" : discovered_areas,
		"persistent_data": persistent_data,
	}
	var save_file = FileAccess.open(get_file_name(), FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save_data))


func save_game(current_scene: String = SceneManager.current_scene) -> void:
	var player: Player = await SceneManager.get_player()
	var zeroed_pos = player.global_position - SceneManager.level_offset
	save_data = {
		"scene_path" : current_scene,
		"x" : zeroed_pos.x,
		"y" : zeroed_pos.y,
		"health" : player.health,
		"max_health" : player.max_health,
		"ability" : false,
		"discovered_areas" : discovered_areas,
		"persistent_data": persistent_data,
	}
	var save_file = FileAccess.open(get_file_name(), FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save_data))

	print("saved to slot " + str(current_slot + 1))


func load_game() -> void:
	if not FileAccess.file_exists(get_file_name()):
		return

	var save_file = FileAccess.open(get_file_name(), FileAccess.READ)
	save_data = JSON.parse_string(save_file.get_line())

	persistent_data = save_data.get("persistent_data", {})
	discovered_areas = save_data.get("discovered_areas", [])
	var scene_path = save_data.get("scene_path", new_game_scene)
	SceneManager.transition_scene(scene_path, "", Vector2.ZERO, "up", false)
	await SceneManager.new_scene_ready
	setup_player()


func setup_player()-> void:
	var player: Player = await SceneManager.get_player()
	player.set_health_check_reset(save_data.get("health", 3), false)
	player.max_health = save_data.get("max_health", 3)
	player.global_position = Vector2(save_data.get("x", 0),
			save_data.get("y", 0))

	player.reset_flags()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("save"):
			save_game()
		elif event.is_action_pressed("load"):
			load_game()
		elif event.is_action_pressed("change_slot_1"):
			current_slot = 0
			print("save slot set to 1")
		elif event.is_action_pressed("change_slot_2"):
			current_slot = 1
			print("save slot set to 2")
		elif event.is_action_pressed("change_slot_3"):
			current_slot = 2
			print("save slot set to 3")


func get_file_name() -> String:
	return "user://" + SLOTS[current_slot] + ".sav"
