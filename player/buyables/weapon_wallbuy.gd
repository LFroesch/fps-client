@tool
extends BuyableBase
class_name WeaponWallbuy

enum WeaponType { PISTOL, SMG, SHOTGUN, SNIPER, ASSAULT_RIFLE, LMG, GRENADES }

@export var weapon_type: WeaponType = WeaponType.PISTOL:
	set(value):
		weapon_type = value
		_update_weapon_display()

# Cost tables matching server-side
const WEAPON_COSTS = {
	0: 0,       # Pistol (free starter)
	1: 1000,    # SMG
	2: 1500,    # Shotgun
	3: 3000,    # Sniper
	4: 2000,    # Assault Rifle
	5: 2500     # LMG
}

const AMMO_COSTS = {
	0: 0,       # Pistol
	1: 500,     # SMG
	2: 500,     # Shotgun
	3: 1000,    # Sniper
	4: 750,     # Assault Rifle
	5: 750      # LMG
}

var weapon_display: Node3D
var info_label: Label3D

func _ready() -> void:
	if Engine.is_editor_hint():
		_update_weapon_display()
		return

	# Set buyable properties with weapon-specific costs
	var weapon_id = _get_weapon_id()
	buyable_id = "weapon_%d" % weapon_id
	buyable_name = _get_weapon_name()

	# Grenades have special cost (500 for refill)
	if weapon_type == WeaponType.GRENADES:
		cost = 500
	else:
		cost = WEAPON_COSTS.get(weapon_id, 1000)

	super._ready()

func setup_visuals() -> void:
	# Create weapon display at runtime
	_update_weapon_display()

func _update_weapon_display() -> void:
	if not is_inside_tree():
		return

	# Clear existing weapon display
	if weapon_display and is_instance_valid(weapon_display):
		remove_child(weapon_display)
		weapon_display.free()
		weapon_display = null
		info_label = null

	# Create new weapon display from scene
	var weapon_scene = _get_weapon_scene()
	if weapon_scene:
		weapon_display = weapon_scene.instantiate()
		weapon_display.name = "WeaponDisplay"
		weapon_display.position = Vector3(0, 1.5, 0)
		weapon_display.rotation_degrees = Vector3(0, -90, 0)

		# Mark grenades as display-only to prevent indicator
		if weapon_type == WeaponType.GRENADES and "is_display_only" in weapon_display:
			weapon_display.is_display_only = true

		add_child(weapon_display)

		# Add label below the weapon - counter-rotate to face forward
		# Get weapon-specific offset for centering
		var label_offset = _get_label_offset()

		info_label = Label3D.new()
		info_label.name = "InfoLabel"
		info_label.position = label_offset
		info_label.rotation_degrees = Vector3(0, 90, 0)  # Counter the weapon's -90° rotation
		info_label.pixel_size = 0.005
		info_label.modulate = Color.WHITE
		info_label.outline_modulate = Color.BLACK
		info_label.outline_size = 8
		info_label.font_size = 32
		info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_update_label_text()
		weapon_display.add_child(info_label)

func _get_label_offset() -> Vector3:
	# Per-weapon label positioning to center text under each weapon
	# Due to weapon rotation: X = forward/back, Y = up/down, Z = left/right
	match weapon_type:
		WeaponType.PISTOL: return Vector3(0, -0.5, -0.05)
		WeaponType.SMG: return Vector3(0, -0.5, -0.15)
		WeaponType.SHOTGUN: return Vector3(0, -0.5, -0.15)
		WeaponType.SNIPER: return Vector3(0, -0.5, -0.2)
		WeaponType.ASSAULT_RIFLE: return Vector3(0, -0.5, -0.1)
		WeaponType.LMG: return Vector3(0, -0.5, -0.15)
		WeaponType.GRENADES: return Vector3(0, -0.5, 0)
		_: return Vector3(0, -0.5, 0)

func _update_label_text() -> void:
	if not info_label:
		return

	var has_weapon = _player_has_weapon()
	var weapon_name = _get_weapon_name().to_upper()
	var weapon_id = _get_weapon_id()

	if has_weapon:
		var ammo_cost = AMMO_COSTS.get(weapon_id, 500)
		info_label.text = "AMMO\n%d POINTS" % ammo_cost
	else:
		var weapon_cost = WEAPON_COSTS.get(weapon_id, 1000)
		info_label.text = "%s\n%d POINTS" % [weapon_name, weapon_cost]

func _get_weapon_scene() -> PackedScene:
	match weapon_type:
		WeaponType.PISTOL: return preload("res://player/weapons/weapon_pistol.tscn")
		WeaponType.SMG: return preload("res://player/weapons/weapon_smg.tscn")
		WeaponType.SHOTGUN: return preload("res://player/weapons/weapon_shotgun.tscn")
		WeaponType.SNIPER: return preload("res://player/weapons/weapon_sniper.tscn")
		WeaponType.ASSAULT_RIFLE: return preload("res://player/weapons/weapon_assault_rifle.tscn")
		WeaponType.LMG: return preload("res://player/weapons/weapon_lmg.tscn")
		WeaponType.GRENADES: return preload("res://player/grenade/grenade.tscn")
		_: return null

func _get_weapon_id() -> int:
	return int(weapon_type)

func get_prompt_text() -> String:
	var weapon_name = _get_weapon_name()
	var has_weapon = _player_has_weapon()
	var weapon_id = _get_weapon_id()

	if has_weapon:
		# Ammo purchase - show hold confirmation
		var ammo_cost = AMMO_COSTS.get(weapon_id, 500)
		return "Hold F to refill ammo for %s\nCost: %d points" % [weapon_name, ammo_cost]
	else:
		var weapon_cost = WEAPON_COSTS.get(weapon_id, 1000)
		return "Press F to buy %s\nCost: %d points" % [weapon_name, weapon_cost]

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Update hold requirement based on if player owns weapon
	if player_nearby:
		require_hold_confirm = _player_has_weapon()
		_update_label_text()

	super._process(delta)

func can_interact() -> bool:
	# Always can interact (buy weapon or ammo)
	return true

func on_purchase_requested() -> void:
	var weapon_id = _get_weapon_id()

	# Grenades always refill (never ammo vs weapon choice)
	if weapon_type == WeaponType.GRENADES:
		print("Requesting grenade refill")
		get_tree().call_group("Lobby", "try_buy_weapon", weapon_id, false)
		return

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
	match weapon_type:
		WeaponType.PISTOL: return "Pistol"
		WeaponType.SMG: return "SMG"
		WeaponType.SHOTGUN: return "Shotgun"
		WeaponType.SNIPER: return "Sniper"
		WeaponType.ASSAULT_RIFLE: return "Assault Rifle"
		WeaponType.LMG: return "LMG"
		WeaponType.GRENADES: return "Grenades"
		_: return "Unknown"

func _player_has_weapon() -> bool:
	if not player_nearby:
		return false
	if not player_nearby.has_method("get_node"):
		return false

	var weapon_holder = player_nearby.get_node_or_null("WeaponHolder")
	if not weapon_holder or not weapon_holder.has_method("has_weapon_in_inventory"):
		return false

	return weapon_holder.has_weapon_in_inventory(_get_weapon_id())
