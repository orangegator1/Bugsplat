@icon("uid://l40ea7g3ctdl")

class_name InputHint extends Node2D

const HINT_MAP : Dictionary = {
	"keyboard" : {
		"jump" : 0,
		"left" : 1,
		"down" : 2,
		"right" : 3,
		"interact" : 4,
	},
	"playstation" : {
		"jump" : 5,
		"left" : 16,
		"down" : 15,
		"right" : 14,
		"interact" : 6,
	},
	"xbox" : {
		"jump" : 11,
		"left" : 16,
		"down" : 15,
		"right" : 14,
		"interact" : 9,
	},
}

var controller_type: String = "keyboard"

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = false
	MessageBus.input_hint_changed.connect(on_input_hint_changed)

func _input(event)-> void:
	if event is InputEventMouseButton or event is InputEventKey:
		controller_type = "keyboard"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_controller_type(event.device)
		pass

func get_controller_type(device_id: int) -> void:
	var n: String = Input.get_joy_name(device_id).to_lower()
	if "playstation" in n or "ps" in n or "dualsense" in n:
		controller_type = "playstation"
	elif "xbox" in n or "xinput" in n:
		controller_type = "xbox"
	elif "nintendo" in n or "switch" in n:
		controller_type = "xbox"
	else:
		controller_type = "unknown"
	print(controller_type + " controller connected")

	set_process_input(false)

func on_input_hint_changed(hint: String) -> void:
	if hint == "":
		animation_player.play("fade_out")
		await animation_player.animation_finished
		visible = false
	else:
		sprite_2d.frame = HINT_MAP[controller_type].get(hint, 0)
		visible = true
		animation_player.play_backwards("fade_out")
