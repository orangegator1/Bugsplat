@icon("uid://ja060p5x2vvl")
class_name SavePoint extends Node2D

@onready var area_2d: Area2D = $Area2D
@onready var animation_player: AnimationPlayer = $Node2D/AnimationPlayer

func _ready() -> void:
	area_2d.body_entered.connect(on_player_entered)
	area_2d.body_exited.connect(on_player_exited)

func on_player_entered(_player: Player) -> void:
	MessageBus.player_interacted.connect(on_player_interacted)
	MessageBus.input_hint_changed.emit("interact")

func on_player_exited(_player: Player) -> void:
	MessageBus.player_interacted.disconnect(on_player_interacted)
	MessageBus.input_hint_changed.emit("")

func on_player_interacted(_player: Player) -> void:
	var scene_path = owner.scene_file_path
	SaveManager.save_game(scene_path)
	animation_player.play("game_saved")
