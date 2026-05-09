extends Control

var current_health: int

@onready var player: Player
@onready var health_indicator: AnimatedSprite2D = $HBoxContainer/HealthIndicator
@onready var healed_particles: GPUParticles2D = $HBoxContainer/HealedParticles
@onready var healed_particles_2: GPUParticles2D = $HBoxContainer/HealedParticles2

var pool: Array[GPUParticles2D]
var index := 0

func _ready() -> void:
	pool = [healed_particles, healed_particles_2]

func _process(_delta: float) -> void:
	if player and get_tree().get_first_node_in_group("Player"):
		return
	else:
		# reconnect to new instance of player
		player = await SceneManager.get_player()
		current_health = player.health
		on_player_health_changed(player.health)
		player.health_changed.connect(on_player_health_changed)


func on_player_health_changed(value: int) -> void:
	if value <= 0:
		health_indicator.play("reset")
	elif current_health <= value:
		var particles = pool[index]
		index = (index + 1) % pool.size()
		particles.emitting = true
		health_indicator.play(str(value))
	elif current_health > value:
		health_indicator.play(str(value) + " hurt")
		await health_indicator.animation_finished
		health_indicator.play(str(value))
	current_health = value
