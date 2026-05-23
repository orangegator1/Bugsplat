extends CanvasLayer

var current_health: int

@onready var player: Player
@onready var health_indicator: AnimatedSprite2D = $HBoxContainer/HealthIndicator
@onready var healed_particles: GPUParticles2D = $HBoxContainer/HealedParticles
@onready var healed_particles_2: GPUParticles2D = $HBoxContainer/HealedParticles2
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var pool: Array[GPUParticles2D]
var index := 0
var new_game = false

func _ready() -> void:
	pool = [healed_particles, healed_particles_2]


func _process(_delta: float) -> void:
	if not player or not get_tree().get_first_node_in_group("Player"):
		# reconnect to new instance of player
		player = await SceneManager.get_player()
		current_health = player.health
		on_player_health_changed(player.health)
		if player.health_changed.is_connected(on_player_health_changed):
			player.health_changed.disconnect(on_player_health_changed)
		player.health_changed.connect(on_player_health_changed)


func on_player_health_changed(value: int) -> void:
	if value <= 0:
		health_indicator.play("reset")
	elif current_health < value:
		var particles = pool[index]
		index = (index + 1) % pool.size()
		particles.emitting = true
		health_indicator.play(str(value))
		if new_game:
			new_game_tutorial(1)
	elif current_health > value:
		if new_game:
			new_game_tutorial(0)
		health_indicator.play(str(value) + " hurt")
		await health_indicator.animation_finished
		health_indicator.play(str(value))
	elif current_health == value:
		health_indicator.play(str(value))
	current_health = value


func new_game_tutorial(i: int) -> void:
	if i == 0:
		visible = true
		animation_player.play("tutorial")
	else:
		animation_player.play("tutorial_done")
