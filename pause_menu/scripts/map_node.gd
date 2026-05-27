@tool
@icon("uid://b1p6stt12ncsq")

class_name MapNode extends Control

const SCALE_FACTOR := 40.0

@export_file("*.tscn") var linked_scene: String: set = on_scene_set
@export_tool_button("Update") var update_node_action = update_node

@export var entrances_top: Array[Vector2] = []
@export var entrances_right: Array[Vector2] = []
@export var entrances_bottom: Array[Vector2] = []
@export var entrances_left: Array[Vector2] = []

var indicator_offset: Vector2 = Vector2.ZERO

@onready var label: Label = $Label
@onready var transition_blocks: Control = $TransitionBlocks

func _ready() -> void:
	if Engine.is_editor_hint():
		pass
	else:
		label.queue_free()
		create_transition_blocks()

		# hide the whole level on the minimap if not discovered
		# TODO uncover chunks of large levels one at a time
		if not SaveManager.is_area_discovered(linked_scene):
			visible = false
		elif SceneManager.current_scene == linked_scene:
			display_player_location()


func on_scene_set(value: String) -> void:
	if not linked_scene == value:
		linked_scene = value
		if Engine.is_editor_hint():
			update_node()


func update_node() -> void:
	var new_size = Vector2(480, 270)
	var transitions: Array[LevelTransition] = []

	if ResourceLoader.exists(linked_scene):
		var packed_scene: PackedScene = ResourceLoader.load(linked_scene) as PackedScene
		if packed_scene:
			var instance = packed_scene.instantiate()
			if instance:
				update_node_label(instance)
				for c in instance.get_children():
					if c is GrowableTileset:
						new_size = PlatformManager.get_dimensions(c)
						# offset representing the top-left corner position of the tilemaplayer
						indicator_offset = PlatformManager.get_position(c) * c.tile_size
					elif c is LevelTransition:
						transitions.append(c)
				instance.queue_free()

	size = new_size / SCALE_FACTOR
	size = size.round()
	create_entrance_data(transitions)
	create_transition_blocks()


func update_node_label(scene: Node) -> void:
	if not label:
		label = $Label
	var t: String = scene.scene_file_path
	t = t.replace("res://1_Tangled Levels/","")
	t = t.replace(".tscn","")


func create_entrance_data(transitions: Array[LevelTransition]) -> void:
	entrances_top.clear()
	entrances_right.clear()
	entrances_bottom.clear()
	entrances_left.clear()

	for t in transitions:
		var pos: Vector2 = (t.position - indicator_offset) / SCALE_FACTOR
		var pos_offset = clamp(
					pos, Vector2(2.0, 2.0),
					Vector2(self.size.x - 2.0, self.size.y - 2.0)
				)
		# subtract 3 because transition indicators are drawn top down
		# and level_transitions are the opposite
		if (t.location == SceneManager.SIDE.LEFT
				or t.location == SceneManager.SIDE.RIGHT):
			pos_offset.y += -3.0

		if t.location == SceneManager.SIDE.LEFT:
			entrances_left.append(Vector2(pos_offset))
		elif t.location == SceneManager.SIDE.RIGHT:
			entrances_right.append(Vector2(pos_offset))
		elif t.location == SceneManager.SIDE.TOP:
			entrances_top.append(Vector2(pos_offset))
		elif t.location == SceneManager.SIDE.BOTTOM:
			entrances_bottom.append(Vector2(pos_offset))


func create_transition_blocks() -> void:
	if not transition_blocks:
		transition_blocks = $TransitionBlocks

	for c in transition_blocks.get_children():
		c.queue_free()

	for e in entrances_left:
		var block := add_block()
		block.size.y = 3
		block.position = e

	for e in entrances_right:
		var block := add_block()
		block.size.y = 3
		block.position = e

	for e in entrances_top:
		var block := add_block()
		block.size.x = 3
		block.position = e

	for e in entrances_bottom:
		var block := add_block()
		block.size.x = 3
		block.position = e


func add_block() -> ColorRect:
	var block: ColorRect = ColorRect.new()
	transition_blocks.add_child(block)
	block.custom_minimum_size.x = 1
	block.custom_minimum_size.y = 1
	return block


func display_player_location() -> void:
	var player := await SceneManager.get_player()
	var indicator: Control = %PlayerIndicator
	var tml = PlatformManager.layer
	indicator_offset = PlatformManager.get_position(tml) * tml.tile_size
	var pos = position
	var offsets = indicator_offset + SceneManager.level_offset
	pos += ((player.position - offsets) / SCALE_FACTOR)

	indicator.position = pos
	pass
