extends Node

const SLOTS: Array[String] = ["save_01", "save_02", "save_03", ]
const CONFIG_FILE_PATH := "user://settings.cfg"

var current_slot: int = 0
var save_data: Dictionary
var discovered_areas: Array = []
var persistent_data: Dictionary
signal config_loaded

var new_game_persistent_scene: String = "uid://uv5kig2w3h2p"
var new_game_scene: String = "uid://b5tobrceh3joe"

func _ready() -> void:
	load_config()
	SceneManager.scene_entered.connect(on_scene_entered)


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

	# tutorialize HUD
	UI.new_game = true
	UI.visible = false


func save_game(current_scene: String = SceneManager.current_scene) -> void:
	var player: Player = await SceneManager.get_player()
	var zeroed_pos = player.global_position - SceneManager.level_offset
	var persistent_scene = get_tree().get_first_node_in_group("PersistentScene")
	persistent_scene = ResourceUID.path_to_uid(persistent_scene.scene_file_path)
	persistent_data["owned_cosmetics"] = player.owned_cosmetics
	persistent_data["equipped_cosmetics"] = player.equipped_cosmetics
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
	var persistent_scene = get_tree().get_first_node_in_group("PersistentScene")
	if not persistent_scene:
		var persistent_scene_path = save_data.get("persistent_scene_path", "")
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
	player.owned_cosmetics = persistent_data.get("owned_cosmetics", [])
	player.equipped_cosmetics = persistent_data.get("equipped_cosmetics", [])
	for c in player.equipped_cosmetics:
		player.cosmetics.get_node_or_null(c).visible = true
	player.reset_flags()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("save"):
			save_game()
		elif event.is_action_pressed("load"):
			load_game()
		elif event.is_action_pressed("change_slot_1"):
			current_slot = 0
		elif event.is_action_pressed("change_slot_2"):
			current_slot = 1
		elif event.is_action_pressed("change_slot_3"):
			current_slot = 2


func get_file_name(slot: int = current_slot) -> String:
	return "user://" + SLOTS[slot] + ".sav"


func save_file_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_file_name(slot))


func is_area_discovered(scene_uid: String) -> bool:
	return discovered_areas.has(scene_uid)


func on_scene_entered(scene_uid: String) -> void:
	if not is_area_discovered(scene_uid):
		discovered_areas.append(scene_uid)


func save_config() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", AudioServer.get_bus_volume_linear(2))
	config.set_value("audio", "sfx", AudioServer.get_bus_volume_linear(3))
	config.set_value("audio", "ui", AudioServer.get_bus_volume_linear(4))
	config.set_value("window", "size", GameManager.preferred_size)
	config.save(CONFIG_FILE_PATH)


func load_config() -> void:
	var config := ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	if err != OK:
		AudioServer.set_bus_volume_linear(2, 0.5)
		AudioServer.set_bus_volume_linear(3, 0.5)
		AudioServer.set_bus_volume_linear(4, 0.5)
		return

	AudioServer.set_bus_volume_linear(2,
			config.get_value("audio", "music", 0.5))
	AudioServer.set_bus_volume_linear(3,
			config.get_value("audio", "sfx", 0.5))
	AudioServer.set_bus_volume_linear(4,
			config.get_value("audio", "ui", 0.5))
	GameManager.preferred_size = config.get_value("window", "size", 1)
	config_loaded.emit()
