@tool
extends BuyableBase
class_name WeaponForge

enum ForgeType { STANDARD, ADVANCED, ULTIMATE }

@export var forge_type: ForgeType = ForgeType.STANDARD:
	set(value):
		forge_type = value
		_update_forge_mesh()

@export var upgrade_cost: int = 5000
@export var upgrade_duration: float = 3.0
@export var max_upgrade_tier: int = 10  # Maximum upgrade tier (expandable)

var is_in_use: bool = false
var forge_mesh: MeshInstance3D
var upgrade_particles: GPUParticles3D
var info_label: Label3D

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_forge_mesh()
		_create_info_label()
		return

	# Set buyable properties
	buyable_id = "weapon_forge"
	buyable_name = "Weapon Forge"
	cost = upgrade_cost
	prompt_text = "Press F to upgrade weapon"

	# Add to group for RPC notifications
	add_to_group("WeaponForge")

	super._ready()

func setup_visuals() -> void:
	_update_forge_mesh()

	# Add info label
	_create_info_label()

	# Add upgrade particle effect (disabled by default)
	upgrade_particles = GPUParticles3D.new()
	upgrade_particles.emitting = false
	upgrade_particles.one_shot = true
	upgrade_particles.amount = 100
	upgrade_particles.lifetime = upgrade_duration
	upgrade_particles.position = Vector3(0, 2, 0)
	add_child(upgrade_particles)

	# TODO: Configure particle material for upgrade effect

func _update_forge_mesh() -> void:
	if not is_inside_tree():
		return

	forge_mesh = get_node_or_null("ForgeMesh")
	if not forge_mesh:
		# Create mesh if it doesn't exist
		forge_mesh = MeshInstance3D.new()
		forge_mesh.name = "ForgeMesh"
		add_child(forge_mesh)

	# Always set mesh properties
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.5, 2.5, 1.5)
	forge_mesh.mesh = box_mesh
	forge_mesh.position = Vector3(0, 1.25, 0)

	if not forge_mesh.material_override:
		forge_mesh.material_override = StandardMaterial3D.new()

	var material = forge_mesh.material_override
	material.metallic = 0.8
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission_energy_multiplier = 0.5

	var color = _get_forge_color()
	material.albedo_color = color
	material.emission = color

	# Update label if it exists
	if info_label and not Engine.is_editor_hint():
		_update_label_text()

func _create_info_label() -> void:
	if info_label:
		return

	info_label = Label3D.new()
	info_label.name = "InfoLabel"
	info_label.position = Vector3(0, 0.5, 1.2)  # In front of forge
	info_label.rotation_degrees = Vector3(0, 0, 0)
	info_label.pixel_size = 0.004
	info_label.modulate = Color.WHITE
	info_label.outline_modulate = Color.BLACK
	info_label.outline_size = 10
	info_label.font_size = 40
	info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_update_label_text()

	if forge_mesh:
		forge_mesh.add_child(info_label)
	else:
		add_child(info_label)

func _update_label_text() -> void:
	if not info_label:
		return

	var forge_name = _get_forge_name()
	info_label.text = "%s\n%d POINTS" % [forge_name, upgrade_cost]

func _get_forge_name() -> String:
	match forge_type:
		ForgeType.STANDARD: return "WEAPON FORGE"
		ForgeType.ADVANCED: return "ADVANCED FORGE"
		ForgeType.ULTIMATE: return "ULTIMATE FORGE"
		_: return "WEAPON FORGE"

func _get_forge_color() -> Color:
	match forge_type:
		ForgeType.STANDARD: return Color(0.3, 0.3, 0.4)
		ForgeType.ADVANCED: return Color(0.8, 0.4, 0.1)
		ForgeType.ULTIMATE: return Color(0.8, 0.2, 0.8)
		_: return Color(0.5, 0.5, 0.5)

func can_interact() -> bool:
	if is_in_use:
		return false

	# Check if player has a weapon that can be upgraded
	if not player_nearby:
		return false

	return _player_has_upgradeable_weapon()

func update_prompt() -> void:
	# Always show prompt messages, even if can't interact
	get_tree().call_group("InteractionPrompt", "show_prompt", get_prompt_text())

func get_prompt_text() -> String:
	if is_in_use:
		return "Weapon Forge in use..."

	if not player_nearby:
		return "Weapon Forge"

	var weapon_holder = player_nearby.get_node_or_null("Head/LocalWeaponHolder")
	if not weapon_holder or not weapon_holder.weapon:
		return "No weapon equipped"

	# Check current upgrade tier
	var current_tier = weapon_holder.weapon.get_meta("upgrade_tier", 0)
	if current_tier >= max_upgrade_tier:
		return "Weapon fully upgraded (Tier %d)" % current_tier

	var next_tier = current_tier + 1
	return "Press F to upgrade weapon (Tier %d → %d)\nCost: %d points" % [current_tier, next_tier, cost]

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

	var weapon_holder = player_nearby.get_node_or_null("Head/LocalWeaponHolder")
	if not weapon_holder or not weapon_holder.weapon:
		return false

	# Check if weapon can still be upgraded
	var current_tier = weapon_holder.weapon.get_meta("upgrade_tier", 0)
	if current_tier >= max_upgrade_tier:
		return false  # Already at max tier

	return true

func _get_current_weapon_id() -> int:
	if not player_nearby:
		return -1

	var weapon_holder = player_nearby.get_node_or_null("Head/LocalWeaponHolder")
	if not weapon_holder or not weapon_holder.has_method("get_current_weapon_id"):
		return -1

	return weapon_holder.get_current_weapon_id()
