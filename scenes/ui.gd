extends Control

var current_health: int

@onready var player: CharacterBody2D
@onready var health_indicator: AnimatedSprite2D = $HBoxContainer/HealthIndicator
@onready var healed_particles: GPUParticles2D = $HBoxContainer/HealedParticles
@onready var healed_particles_2: GPUParticles2D = $HBoxContainer/HealedParticles2

var pool: Array[GPUParticles2D]
var index := 0

func _ready() -> void:
	while not player:
			await get_tree().process_frame
			player = get_tree().get_first_node_in_group("Player")
	current_health = player.health

	pool = [healed_particles, healed_particles_2]
	#for p in pool:
		#p.emitting = true
		#p.modulate.a = 0.0

func _on_player_health_changed(value: int) -> void:
	if value <= 0:
		health_indicator.play("reset")
	elif current_health < value:
		var particles = pool[index]
		#particles.modulate.a = 1.0
		index = (index + 1) % pool.size()
		particles.emitting = true
		health_indicator.play(str(value))
	elif current_health > value:
		health_indicator.play(str(value) + " hurt")
		await health_indicator.animation_finished
		health_indicator.play(str(value))
	current_health = value
