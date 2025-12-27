extends BuyableBase
class_name PerkMachine

@export_enum("TacticalVest", "FastHands", "RapidFire", "CombatMedic", "Endurance", "Marksman", "BlastShield", "HeavyGunner") var perk_type: String = "TacticalVest"
@export var perk_color: Color = Color.RED

var machine_mesh: MeshInstance3D
var has_been_purchased: bool = false

# Perk data
var perk_data = {
	"TacticalVest": {"cost": 2500, "name": "Tactical Vest", "desc": "+100% max HP", "color": Color(0.2, 0.6, 0.2)},
	"FastHands": {"cost": 3000, "name": "Fast Hands", "desc": "+50% reload speed", "color": Color(0.8, 0.4, 0.0)},
	"RapidFire": {"cost": 2000, "name": "Rapid Fire", "desc": "+33% fire rate", "color": Color(0.9, 0.2, 0.2)},
	"CombatMedic": {"cost": 1500, "name": "Combat Medic", "desc": "+75% revive speed", "color": Color(0.3, 0.7, 0.9)},
	"Endurance": {"cost": 2000, "name": "Endurance Training", "desc": "+25% movement speed", "color": Color(0.9, 0.9, 0.2)},
	"Marksman": {"cost": 1500, "name": "Marksman", "desc": "+10% headshot damage", "color": Color(0.5, 0.3, 0.8)},
	"BlastShield": {"cost": 2500, "name": "Blast Shield", "desc": "Immune to explosives", "color": Color(0.4, 0.4, 0.4)},
	"HeavyGunner": {"cost": 4000, "name": "Heavy Gunner", "desc": "+1 weapon slot", "color": Color(0.6, 0.2, 0.1)}
}

func _ready() -> void:
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

	super._ready()

func setup_visuals() -> void:
	# Create perk machine (vending machine style)
	machine_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1.5, 2.2, 1)
	machine_mesh.mesh = mesh
	machine_mesh.position = Vector3(0, 1.1, 0)

	var material = StandardMaterial3D.new()
	material.albedo_color = perk_color
	material.metallic = 0.3
	material.roughness = 0.5

	# Add emission for glow effect
	material.emission_enabled = true
	material.emission = perk_color
	material.emission_energy = 0.5

	machine_mesh.material_override = material
	add_child(machine_mesh)

	# Add label/text above machine
	# TODO: Add Label3D with perk name

func can_interact() -> bool:
	if has_been_purchased:
		return false

	# Check if player already has this perk
	if _player_has_perk():
		return false

	return true

func get_prompt_text() -> String:
	if has_been_purchased or _player_has_perk():
		return "%s already purchased" % buyable_name

	var data = perk_data.get(perk_type, {})
	var desc = data.get("desc", "")
	return "Press F to buy %s\n%s\nCost: %d points" % [buyable_name, desc, cost]

func on_purchase_requested() -> void:
	print("Requesting perk purchase: ", perk_type)
	get_tree().call_group("Lobby", "try_buy_perk", perk_type)

func on_purchase_success() -> void:
	super.on_purchase_success()
	has_been_purchased = true

	# Dim the machine to show it's been used
	if machine_mesh and machine_mesh.material_override:
		var material = machine_mesh.material_override as StandardMaterial3D
		material.emission_energy = 0.1
		material.albedo_color = material.albedo_color.darkened(0.5)

func _player_has_perk() -> bool:
	if not player_nearby:
		return false

	# TODO: Check player's perk list
	# For now, return false
	return false
