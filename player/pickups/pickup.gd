extends Node3D
class_name Pickup

const READY_MATERIAL := preload("res://asset_packs/tutorial-fps-assets/materials/pickup_ready_material.tres")
const NOT_READY_MATERIAL := preload("res://asset_packs/tutorial-fps-assets/materials/pickup_not_ready_material.tres")

@onready var platform: CSGCylinder3D = %Platform
@onready var mesh_holder: Node3D = $MeshHolder

enum PickupTypes {
	HealthPickup = 0,
	GrenadePickup = 1,
	AmmoPickup = 2,         # Max Ammo (refills all weapons)
	InstaKill = 4,
	DoublePoints = 5,
	Nuke = 6
}

var pickup_type : PickupTypes

func _ready() -> void:
	match pickup_type:
		PickupTypes.HealthPickup:
			mesh_holder.add_child(load("res://asset_packs/tutorial-fps-assets/meshes/items/health.tscn").instantiate())
		PickupTypes.GrenadePickup:
			mesh_holder.add_child(load("res://asset_packs/tutorial-fps-assets/meshes/items/grenade.tscn").instantiate())
		PickupTypes.AmmoPickup:
			mesh_holder.add_child(load("res://player/pickups/ammo.tscn").instantiate())
		PickupTypes.InstaKill:
			mesh_holder.add_child(_create_powerup_box(Color(1.0, 0.2, 0.2)))  # Red
		PickupTypes.DoublePoints:
			mesh_holder.add_child(_create_powerup_box(Color(1.0, 0.85, 0.0)))  # Gold
		PickupTypes.Nuke:
			mesh_holder.add_child(_create_powerup_box(Color(0.1, 1.0, 0.1)))  # Green

func _create_powerup_box(color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.4, 0.4, 0.4)
	mesh_instance.mesh = box_mesh

	# Create emissive material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	mesh_instance.set_surface_override_material(0, material)

	# Add rotation animation
	var tween_rotation = func():
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(mesh_instance, "rotation:y", TAU, 2.0)
	tween_rotation.call_deferred()

	return mesh_instance
func cooldown_started() -> void:
	platform.material = NOT_READY_MATERIAL
	mesh_holder.hide()

func cooldown_ended() -> void:
	platform.material = READY_MATERIAL
	mesh_holder.show()

var despawn_timer : Timer
var flash_timer : Timer

func start_despawn_countdown(despawn_time : float) -> void:
	# Create despawn timer
	despawn_timer = Timer.new()
	add_child(despawn_timer)
	despawn_timer.wait_time = despawn_time
	despawn_timer.one_shot = true
	despawn_timer.timeout.connect(_on_despawn)
	despawn_timer.start()

	# Start flash warning in last 5 seconds using a timer
	var flash_warning_time = despawn_time - 5.0
	if flash_warning_time > 0:
		var warning_timer = Timer.new()
		add_child(warning_timer)
		warning_timer.wait_time = flash_warning_time
		warning_timer.one_shot = true
		warning_timer.timeout.connect(start_flash_warning)
		warning_timer.start()
	else:
		start_flash_warning()

func start_flash_warning() -> void:
	# Use a repeating timer instead of async loop
	flash_timer = Timer.new()
	add_child(flash_timer)
	flash_timer.wait_time = 0.2
	flash_timer.timeout.connect(_toggle_visibility)
	flash_timer.start()

func _toggle_visibility() -> void:
	if is_instance_valid(mesh_holder):
		mesh_holder.visible = !mesh_holder.visible

func _on_despawn() -> void:
	if flash_timer:
		flash_timer.stop()
	queue_free()
