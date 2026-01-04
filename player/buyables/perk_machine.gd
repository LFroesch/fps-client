@tool
extends BuyableBase
class_name PerkMachine

@export_enum("TacticalVest", "FastHands", "RapidFire", "CombatMedic", "Endurance", "Marksman", "BlastShield", "HeavyGunner") var perk_type: String = "TacticalVest":
	set(value):
		perk_type = value
		_update_machine_mesh()

@export var perk_color: Color = Color.RED:
	set(value):
		perk_color = value
		_update_machine_mesh()

var machine_mesh: MeshInstance3D
var info_label: Label3D

# Perk data
var perk_data = {
	"TacticalVest": {"cost": 2500, "name": "Tactical Vest", "desc": "+100% max HP", "color": Color(0.2, 0.6, 0.2)},
	"FastHands": {"cost": 3000, "name": "Fast Hands", "desc": "+50% reload speed", "color": Color(0.8, 0.4, 0.0)},
	"RapidFire": {"cost": 2000, "name": "Rapid Fire", "desc": "+33% fire rate", "color": Color(0.9, 0.2, 0.2)},
	"CombatMedic": {"cost": 1500, "name": "Combat Medic", "desc": "+75% revive speed", "color": Color(0.3, 0.7, 0.9)},
	"Endurance": {"cost": 2000, "name": "Endurance Training", "desc": "+25% movement speed", "color": Color(0.9, 0.9, 0.2)},
	"Marksman": {"cost": 1500, "name": "Marksman", "desc": "+50% headshot damage", "color": Color(0.5, 0.3, 0.8)},
	"BlastShield": {"cost": 2500, "name": "Blast Shield", "desc": "Immune to explosives", "color": Color(0.4, 0.4, 0.4)},
	"HeavyGunner": {"cost": 4000, "name": "Heavy Gunner", "desc": "+1 weapon slot", "color": Color(0.6, 0.2, 0.1)}
}

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_machine_mesh()
		_create_info_label()
		return

	# Set buyable properties from perk data
	var data = perk_data.get(perk_type, {})
	buyable_id = "perk_%s" % perk_type
	buyable_name = data.get("name", perk_type)
	cost = data.get("cost", 1000)
	prompt_text = "Press F to buy %s" % buyable_name
	one_time_purchase = true

	# Set color if not customized
	if perk_color == Color.RED:  # Default value
		perk_color = data.get("color", Color.RED)

	# Add to group for RPC notifications
	add_to_group("PerkMachine")

	super._ready()

func setup_visuals() -> void:
	_update_machine_mesh()
	_create_info_label()

func _update_machine_mesh() -> void:
	if not is_inside_tree():
		return

	machine_mesh = get_node_or_null("MachineMesh")
	if not machine_mesh:
		# Create mesh if it doesn't exist
		machine_mesh = MeshInstance3D.new()
		machine_mesh.name = "MachineMesh"
		add_child(machine_mesh)

	# Always set mesh properties
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.2, 2.5, 0.8)
	machine_mesh.mesh = box_mesh
	machine_mesh.position = Vector3(0, 1.25, 0)

	if not machine_mesh.material_override:
		machine_mesh.material_override = StandardMaterial3D.new()

	var material = machine_mesh.material_override
	material.metallic = 0.3
	material.roughness = 0.5
	material.emission_enabled = true
	material.emission_energy_multiplier = 0.8

	# Get color from perk data if using default
	var color = perk_color
	if perk_color == Color.RED:
		var data = perk_data.get(perk_type, {})
		color = data.get("color", Color.RED)

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
	info_label.position = Vector3(0, 0.5, 1.0)  # In front of machine
	info_label.rotation_degrees = Vector3(0, 0, 0)
	info_label.pixel_size = 0.004
	info_label.modulate = Color.WHITE
	info_label.outline_modulate = Color.BLACK
	info_label.outline_size = 10
	info_label.font_size = 40
	info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_update_label_text()

	if machine_mesh:
		machine_mesh.add_child(info_label)
	else:
		add_child(info_label)

func _update_label_text() -> void:
	if not info_label:
		return

	var data = perk_data.get(perk_type, {})
	var perk_name = data.get("name", perk_type).to_upper()
	var perk_cost = data.get("cost", cost)
	info_label.text = "%s\n%d POINTS" % [perk_name, perk_cost]

func can_interact() -> bool:
	# Check if player already has this perk
	if _player_has_perk():
		return false

	return true

func get_prompt_text() -> String:
	if _player_has_perk():
		return "%s already purchased" % buyable_name

	var data = perk_data.get(perk_type, {})
	var desc = data.get("desc", "")
	return "Press F to buy %s\n%s\nCost: %d points" % [buyable_name, desc, cost]

func on_purchase_requested() -> void:
	print("Requesting perk purchase: ", perk_type)
	get_tree().call_group("Lobby", "try_buy_perk", perk_type)

func on_purchase_success() -> void:
	super.on_purchase_success()

	# Visual feedback only - don't prevent future purchases by other players
	# The machine stays active for other players to buy this perk

func _player_has_perk() -> bool:
	if not player_nearby:
		return false

	# Check if player has this perk in metadata
	if player_nearby.has_meta("perks"):
		var perks = player_nearby.get_meta("perks")
		return perk_type in perks

	return false
