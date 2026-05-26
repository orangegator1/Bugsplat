@icon("uid://l40ea7g3ctdl")

extends Node2D

const HINT_MAP : Dictionary = {
	"keyboard" : {
		"jump" : 0,
		"left" : 1,
		"down" : 2,
		"right" : 3,
		"interact" : 4,
		"toggle_fullscreen" : 17,
		"zoom_in" : 4,
		"zoom_out" : 18,
		"cancel" : 19,
	},
	"playstation" : {
		"jump" : 5,
		"left" : 16,
		"down" : 15,
		"right" : 14,
		"interact" : 6,
		"toggle_fullscreen" : 12,
		"zoom_in" : 6,
		"zoom_out" : 5,
		"cancel" : 8,
	},
	"xbox" : {
		"jump" : 11,
		"left" : 16,
		"down" : 15,
		"right" : 14,
		"interact" : 9,
		"toggle_fullscreen" : 12,
		"zoom_in" : 9,
		"zoom_out" : 11,
		"cancel" : 10,
	},
	"nintendo" : {
		"jump" : 10,
		"left" : 16,
		"down" : 15,
		"right" : 14,
		"interact" : 5,
		"toggle_fullscreen" : 12,
		"zoom_in" : 10,
		"zoom_out" : 5,
		"cancel" : 11,
	},
}

@export_enum("jump", "left", "right", "down", "toggle_fullscreen",
		"interact", "zoom_in", "zoom_out", "cancel") var action := "interact"

var controller_type: String = "keyboard"

@onready var sprite_2d: Sprite2D = $Sprite/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var map: Control = %Map
@onready var pause_screen: Control = %PauseScreen
var text: Node2D
var text_animation_player: AnimationPlayer

func _ready() -> void:
	visible = false
	MessageBus.input_hint_changed.connect(on_input_hint_changed)
	MessageBus.map_selected.connect(on_focus_entered)

	text = get_node_or_null("InputHintText")
	if text:
		text_animation_player = text.get_node_or_null("AnimationPlayer")


func on_focus_entered(flag: bool) -> void:
	if flag:
		on_input_hint_changed(action)
	else:
		on_input_hint_changed("")
	print("signal received")


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
	elif "nintendo" in n or "switch" in n:
		controller_type = "nintendo"
	else:
		controller_type = "xbox"


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
