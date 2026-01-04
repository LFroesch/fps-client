extends Node3D
class_name BulletTrail

var mesh_instance: MeshInstance3D
var lifetime: float = 0.3
var elapsed: float = 0.0

func _ready() -> void:
	# Create mesh instance if not already set
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)

func setup(from_pos: Vector3, to_pos: Vector3, config: Dictionary) -> void:
	# Create cylinder mesh aligned along the ray path
	var cylinder := CylinderMesh.new()
	var distance := from_pos.distance_to(to_pos)

	cylinder.height = distance
	cylinder.top_radius = config.get("trail_width", 0.05)
	cylinder.bottom_radius = config.get("trail_width", 0.05)
	cylinder.radial_segments = 8  # Low poly for performance
	cylinder.rings = 1

	mesh_instance.mesh = cylinder

	# Create glowing material
	var material := StandardMaterial3D.new()
	material.albedo_color = config.get("trail_color", Color.WHITE)
	material.emission_enabled = true
	material.emission = config.get("trail_color", Color.WHITE)
	material.emission_energy_multiplier = config.get("trail_glow", 2.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_receive_shadows = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from all angles

	mesh_instance.material_override = material

	# Position and orient the trail
	var midpoint := (from_pos + to_pos) / 2.0
	global_position = midpoint

	# Orient cylinder along the path (cylinder default is Y-up)
	var direction := (to_pos - from_pos).normalized()
	if not direction.is_zero_approx():
		# Align Y-axis with direction
		look_at(global_position + direction, Vector3.UP)
		rotate_object_local(Vector3.RIGHT, PI / 2)  # Rotate to align cylinder

	# Set lifetime
	lifetime = config.get("trail_lifetime", 0.3)

func _process(delta: float) -> void:
	elapsed += delta

	# Fade out over time
	if mesh_instance and mesh_instance.material_override:
		var fade_progress := elapsed / lifetime
		var material: StandardMaterial3D = mesh_instance.material_override

		# Fade alpha
		var color: Color = material.albedo_color
		color.a = 1.0 - fade_progress
		material.albedo_color = color

		var emission_color: Color = material.emission
		emission_color.a = 1.0 - fade_progress
		material.emission = emission_color

	# Despawn when lifetime expires
	if elapsed >= lifetime:
		queue_free()
