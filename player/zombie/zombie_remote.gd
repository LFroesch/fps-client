extends Node3D
class_name ZombieRemote

enum ZombieType {
	NORMAL,
	FAST,
	TANK
}

const HEALTH_BAR_HEIGHT := 2.2

var zombie_type : ZombieType = ZombieType.NORMAL
var current_health := 100
var max_health := 100

@onready var mesh_instance : MeshInstance3D = $MeshInstance3D
@onready var health_bar_container : Node3D = $HealthBarContainer
@onready var health_bar : ProgressBar = $HealthBarContainer/SubViewport/HealthBar

func _ready() -> void:
	# Set material based on zombie type
	var material : StandardMaterial3D = StandardMaterial3D.new()
	match zombie_type:
		ZombieType.NORMAL:
			material.albedo_color = Color(0.6, 0.8, 0.6)  # Greenish
		ZombieType.FAST:
			material.albedo_color = Color(0.9, 0.9, 0.5)  # Yellowish
		ZombieType.TANK:
			material.albedo_color = Color(0.4, 0.4, 0.4)  # Dark gray

	if mesh_instance:
		mesh_instance.set_surface_override_material(0, material)

	# Initialize health bar
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	# Position health bar above zombie
	if health_bar_container:
		health_bar_container.position.y = HEALTH_BAR_HEIGHT

func update_health_bar(health : int, max_hp : int) -> void:
	current_health = health
	max_health = max_hp

	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = health

	# Show health bar when damaged
	if health < max_hp and health_bar_container:
		health_bar_container.show()
