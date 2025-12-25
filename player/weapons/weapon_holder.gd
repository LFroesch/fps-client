extends Node3D
class_name WeaponHolder

var weapon : Weapon

func instantiate_weapon(weapon_id : int) -> void:
	match weapon_id:
		0: # pistol
			weapon = preload("res://player/weapons/weapon_pistol.tscn").instantiate()
		1: # smg
			weapon = preload("res://player/weapons/weapon_smg.tscn").instantiate()
		2: # shotgun
			weapon = preload("res://player/weapons/weapon_shotgun.tscn").instantiate()
		3: #sniper
			weapon = preload("res://player/weapons/weapon_sniper.tscn").instantiate()
		4: #ar
			weapon = preload("res://player/weapons/weapon_assault_rifle.tscn").instantiate()
		5: #lmg
			weapon = preload("res://player/weapons/weapon_lmg.tscn").instantiate()
	weapon.weapon_id = weapon_id
	add_child(weapon)
	weapon.init_ammo()
