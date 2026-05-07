extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: CharacterBody2D

var picked := false

func _on_ready() -> void:
	GameManager.add_possible_point()
	while not player:
		if is_inside_tree():
			await get_tree().process_frame
		if is_inside_tree():
			player = get_tree().get_first_node_in_group("Player")


func _on_body_entered(_body: Node2D) -> void:
	player.set_health_check_reset(1)
	animation_player.play("Pickup")
