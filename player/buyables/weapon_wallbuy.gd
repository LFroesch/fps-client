extends BuyableBase
class_name WeaponWallbuy

@export var weapon_id: int = 1
@export var weapon_cost: int = 1000
@export var ammo_cost: int = 500

var weapon_display: Node3D

func _ready() -> void:
	# Set buyable properties
	buyable_id = "weapon_%d" % weapon_id
	buyable_name = _get_weapon_name()
	cost = weapon_cost

	super._ready()

func setup_visuals() -> void:
	# Create weapon display
	weapon_display = _create_weapon_display()
	if weapon_display:
		weapon_display.position = Vector3(0, 1.5, 0)
		weapon_display.rotation_degrees = Vector3(0, -90, 0)
		add_child(weapon_display)

func get_prompt_text() -> String:
	var weapon_name = _get_weapon_name()
	var has_weapon = _player_has_weapon()

	if has_weapon:
		return "Press F to refill ammo for %s\nCost: %d points" % [weapon_name, ammo_cost]
	else:
		return "Press F to buy %s\nCost: %d points" % [weapon_name, weapon_cost]

func can_interact() -> bool:
	# Always can interact (buy weapon or ammo)
	return true

func on_purchase_requested() -> void:
	var has_weapon = _player_has_weapon()

	if has_weapon:
		# TODO: Show confirmation UI for ammo purchase
		# For now, just send purchase request immediately
		print("Requesting ammo refill for weapon ", weapon_id)
		get_tree().call_group("Lobby", "try_buy_weapon", weapon_id, true)
	else:
		print("Requesting weapon purchase: ", weapon_id)
		get_tree().call_group("Lobby", "try_buy_weapon", weapon_id, false)

func _get_weapon_name() -> String:
	match weapon_id:
		0: return "Pistol"
		1: return "SMG"
		2: return "Shotgun"
		3: return "Assault Rifle"
		4: return "Sniper"
		5: return "LMG"
		_: return "Unknown"

func _player_has_weapon() -> bool:
	if not player_nearby:
		return false
	if not player_nearby.has_method("get_node"):
		return false

	var weapon_holder = player_nearby.get_node_or_null("WeaponHolder")
	if not weapon_holder or not weapon_holder.has_method("has_weapon_in_inventory"):
		return false

	return weapon_holder.has_weapon_in_inventory(weapon_id)

func _create_weapon_display() -> Node3D:
	var weapon: Node3D
	match weapon_id:
		0: weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()
		1: weapon = preload("res://player/weapons/weapon_smg.tscn").instantiate()
		2: weapon = preload("res://player/weapons/weapon_shotgun.tscn").instantiate()
		3: weapon = preload("res://player/weapons/weapon_sniper.tscn").instantiate()
		4: weapon = preload("res://player/weapons/weapon_assault_rifle.tscn").instantiate()
		5: weapon = preload("res://player/weapons/weapon_lmg.tscn").instantiate()
	return weapon
