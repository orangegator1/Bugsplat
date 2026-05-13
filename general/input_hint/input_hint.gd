@tool
@icon("uid://l40ea7g3ctdl")

class_name InputHint extends Node2D

const HINT_MAP : Dictionary = {
	"keyboard" : {
		"jump" : 0,
		"move_left" : 1,
		"down" : 2,
		"move_right" : 3,
		"interact" : 4,
	},
	"playstation" : {
		"jump" : 5,
		"move_left" : 16,
		"down" : 15,
		"move_right" : 14,
		"interact" : 6,
	},
	"xbox" : {
		"jump" : 11,
		"move_left" : 16,
		"down" : 15,
		"move_right" : 14,
		"interact" : 9,
	},
}

@export var owns_collision := false
@export_enum("jump", "move_left", "move_right", "down", "toggle_fullscreen",
		"interact") var action := "interact"
@export var width := 4 :
	set(value):
		width = value
		apply_area_settings()
@export var height := 2 :
	set(value):
		height = value
		apply_area_settings()

var controller_type: String = "keyboard"

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var area_2d: Area2D = $Area2D
var text: Node2D
var text_animation_player: AnimationPlayer

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	visible = false
	MessageBus.input_hint_changed.connect(on_input_hint_changed)

	text = get_node_or_null("InputHintText")
	if text:
		text_animation_player = text.get_node_or_null("AnimationPlayer")

	if owns_collision:
		area_2d.monitoring = true
		area_2d.body_entered.connect(on_player_entered)
		area_2d.body_exited.connect(on_player_exited)

func on_player_entered(_player: Player) -> void:
	on_input_hint_changed(action)

func on_player_exited(_player: Player) -> void:
	on_input_hint_changed("")

func _input(event)-> void:
	if event is InputEventMouseButton or event is InputEventKey:
		controller_type = "keyboard"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_controller_type(event.device)


func get_controller_type(device_id: int) -> void:
	var n: String = Input.get_joy_name(device_id).to_lower()
	if "playstation" in n or "ps" in n or "dualsense" in n:
		controller_type = "playstation"
	elif "xbox" in n or "xinput" in n:
		controller_type = "xbox"
	#elif "nintendo" in n or "switch" in n:
		#controller_type = "xbox"
	else:
		controller_type = "xbox"

	#set_process_input(false)


func on_input_hint_changed(hint: String) -> void:
	if hint == "":
		animation_player.play("fade_out")
		if text_animation_player:
			text_animation_player.play("fade_out")
		await animation_player.animation_finished
	else:
		sprite_2d.frame = HINT_MAP[controller_type].get(hint, 0)
		visible = true
		animation_player.play("fade_in")
		if text_animation_player:
			text.visible = true
			text_animation_player.play("fade_in")


func apply_area_settings() -> void:
	area_2d = get_node_or_null("Area2D")
	if not area_2d:
		return
	area_2d.scale.x = width
	area_2d.scale.y = height
