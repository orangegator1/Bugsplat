extends Node

const SLOTS: Array[String] = ["save_01", "save_02", "save_03", ]

var current_slot: int = 0
var save_data: Dictionary
var discovered_areas: Array = []
var persistent_data: Dictionary

var new_game_persistent_scene: String = "uid://uv5kig2w3h2p"
var new_game_scene: String = "uid://b5tobrceh3joe"

func _ready() -> void:
	pass


func create_new_game_save(slot: int = current_slot) -> void:
	current_slot = slot
	persistent_data.clear()
	discovered_areas.clear()
	discovered_areas.append(new_game_scene)
	save_data = {
		"scene_path" : new_game_scene,
		"persistent_scene_path" : new_game_persistent_scene,
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
	var persistent_scene = get_tree().get_first_node_in_group("PersistentScene")
	persistent_scene = ResourceUID.path_to_uid(persistent_scene.scene_file_path)
	save_data = {
		"scene_path" : current_scene,
		"persistent_scene_path" : persistent_scene,
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


func load_game(slot: int = current_slot) -> void:
	current_slot = slot

	if not FileAccess.file_exists(get_file_name()):
		return

	var save_file = FileAccess.open(get_file_name(), FileAccess.READ)
	save_data = JSON.parse_string(save_file.get_line())

	persistent_data = save_data.get("persistent_data", {})
	discovered_areas = save_data.get("discovered_areas", [])
	var scene_path = save_data.get("scene_path", new_game_scene)

	# load persistent scene if one exists in the save file
	# the persistent scene will add the scene at the scene_path above as a
	# child and only load/unload necessary components to improve load time
	var persistent_scene_path = save_data.get("persistent_scene_path", "")
	var persistent_scene = get_tree().get_first_node_in_group("PersistentScene")
	if not persistent_scene:
		persistent_scene = load(persistent_scene_path).instantiate()
		get_tree().root.add_child(persistent_scene)

	SceneManager.transition_scene(scene_path, "", Vector2.ZERO, "up")
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


func get_file_name(slot: int = current_slot) -> String:
	return "user://" + SLOTS[slot] + ".sav"


func save_file_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_file_name(slot))
