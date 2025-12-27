extends BuyableBase
class_name WeaponForge

@export var upgrade_cost: int = 5000
@export var upgrade_duration: float = 3.0

var is_in_use: bool = false
var forge_mesh: MeshInstance3D
var upgrade_particles: GPUParticles3D

func _ready() -> void:
	# Set buyable properties
	buyable_id = "weapon_forge"
	buyable_name = "Weapon Forge"
	cost = upgrade_cost
	prompt_text = "Press F to upgrade weapon"

	super._ready()

func setup_visuals() -> void:
	# Create forge machine (placeholder)
	forge_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(2, 2, 2)
	forge_mesh.mesh = mesh
	forge_mesh.position = Vector3(0, 1, 0)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.3, 0.4)  # Dark metallic
	material.metallic = 0.8
	material.roughness = 0.2
	forge_mesh.material_override = material

	add_child(forge_mesh)

	# Add upgrade particle effect (disabled by default)
	upgrade_particles = GPUParticles3D.new()
	upgrade_particles.emitting = false
	upgrade_particles.one_shot = true
	upgrade_particles.amount = 100
	upgrade_particles.lifetime = upgrade_duration
	upgrade_particles.position = Vector3(0, 2, 0)
	add_child(upgrade_particles)

	# TODO: Configure particle material for upgrade effect

func can_interact() -> bool:
	if is_in_use:
		return false

	# Check if player has a weapon that can be upgraded
	if not player_nearby:
		return false

	return _player_has_upgradeable_weapon()

func get_prompt_text() -> String:
	if is_in_use:
		return "Weapon Forge in use..."

	if not _player_has_upgradeable_weapon():
		return "No upgradeable weapon equipped"

	return "Press F to upgrade weapon\nCost: %d points" % cost

func on_purchase_requested() -> void:
	if is_in_use:
		return

	# Get current weapon ID from player
	var weapon_id = _get_current_weapon_id()
	if weapon_id < 0:
		return

	print("Requesting weapon upgrade for weapon ID: ", weapon_id)
	get_tree().call_group("Lobby", "try_upgrade_weapon", weapon_id)

func start_upgrade_animation() -> void:
	is_in_use = true

	# Play upgrade animation
	if upgrade_particles:
		upgrade_particles.emitting = true

	# Create glow effect on forge
	var tween = create_tween()
	tween.set_loops(int(upgrade_duration * 2))
	tween.tween_property(forge_mesh.material_override, "emission_energy", 2.0, 0.5)
	tween.tween_property(forge_mesh.material_override, "emission_energy", 0.0, 0.5)

	# Re-enable after duration
	await get_tree().create_timer(upgrade_duration).timeout
	is_in_use = false

	if player_nearby:
		update_prompt()

func _player_has_upgradeable_weapon() -> bool:
	if not player_nearby:
		return false

	var weapon_holder = player_nearby.get_node_or_null("WeaponHolder")
	if not weapon_holder:
		return false

	var current_weapon = weapon_holder.get_node_or_null("CurrentWeapon")
	if not current_weapon:
		return false

	# Check if weapon is already upgraded
	# TODO: Need to track upgrade status on weapons
	# For now, assume all weapons can be upgraded
	return true

func _get_current_weapon_id() -> int:
	if not player_nearby:
		return -1

	var weapon_holder = player_nearby.get_node_or_null("WeaponHolder")
	if not weapon_holder or not weapon_holder.has_method("get_current_weapon_id"):
		return -1

	return weapon_holder.get_current_weapon_id()
