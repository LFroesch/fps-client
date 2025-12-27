extends Node3D
class_name CameraShakeComponent

const MAX_STRENGTH := 1.0

@export var noise_speed := 1.0
@export var noise_settle_per_second := 2.0

var noise := FastNoiseLite.new()

var noise_strength := 0.0

func _ready() -> void:
	noise.frequency = noise_speed * 0.001

func _process(delta: float) -> void:
	if noise_strength <= 0:
		noise_strength = 0
		rotation.x = 0
		rotation.y = 0
	
	rotation.y = noise.get_noise_1d(Time.get_ticks_msec()) * noise_strength * noise_strength
	rotation.x = noise.get_noise_1d(Time.get_ticks_msec() + 10000) * noise_strength * noise_strength
	
	noise_strength -= delta * noise_settle_per_second
	
func add_noise(strength_impulse : float) -> void:
	noise_strength = clampf(noise_strength + strength_impulse, 0, MAX_STRENGTH)
