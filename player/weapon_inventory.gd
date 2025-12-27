extends Node
class_name WeaponInventory

const MAX_WEAPONS = 2  # Player can hold 2 weapons max

var weapons: Array[int] = []  # Array of weapon IDs
var current_weapon_index: int = 0

signal weapon_switched(weapon_id: int)
signal weapon_added(weapon_id: int)
signal weapon_replaced(old_weapon_id: int, new_weapon_id: int)

func _ready() -> void:
	add_to_group("WeaponInventory")

func add_weapon(weapon_id: int) -> Dictionary:
	# Returns: {added: bool, replaced: bool, old_weapon_id: int}

	# Check if we already have this weapon
	if has_weapon(weapon_id):
		return {
			"added": false,
			"replaced": false,
			"old_weapon_id": -1,
			"is_ammo_refill": true
		}

	# If we have space, add it
	if weapons.size() < MAX_WEAPONS:
		weapons.append(weapon_id)
		current_weapon_index = weapons.size() - 1  # Switch to new weapon
		weapon_added.emit(weapon_id)
		return {
			"added": true,
			"replaced": false,
			"old_weapon_id": -1,
			"is_ammo_refill": false
		}

	# No space - replace current weapon
	var old_weapon_id = weapons[current_weapon_index]
	weapons[current_weapon_index] = weapon_id
	weapon_replaced.emit(old_weapon_id, weapon_id)
	return {
		"added": true,
		"replaced": true,
		"old_weapon_id": old_weapon_id,
		"is_ammo_refill": false
	}

func has_weapon(weapon_id: int) -> bool:
	return weapon_id in weapons

func get_current_weapon_id() -> int:
	if weapons.is_empty():
		return -1
	return weapons[current_weapon_index]

func get_weapon_count() -> int:
	return weapons.size()

func switch_weapon() -> void:
	if weapons.size() <= 1:
		return  # Nothing to switch to

	# Cycle to next weapon
	current_weapon_index = (current_weapon_index + 1) % weapons.size()
	weapon_switched.emit(weapons[current_weapon_index])

func switch_to_weapon_id(weapon_id: int) -> bool:
	var index = weapons.find(weapon_id)
	if index == -1:
		return false

	current_weapon_index = index
	weapon_switched.emit(weapons[current_weapon_index])
	return true

func get_all_weapons() -> Array[int]:
	return weapons.duplicate()

func clear_weapons() -> void:
	weapons.clear()
	current_weapon_index = 0
