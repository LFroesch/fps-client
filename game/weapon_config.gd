class_name WeaponConfig

const WEAPON_DATA := {
	#pistol - reliable starter weapon
	0 : {"name" : "Pistol", "damage" : 30, "accuracy" : 0.95, "projectiles" : 1,
	"mag_size" : 12, "reserve_ammo" : 60, "reload_time" : 1.5,
	"is_automatic" : false, "shot_cooldown" : 0.3,
	"ads_offset" : Vector3(0.0, -0.022, -0.05), "ads_scale" : 1.2,
	"recoil_rotation_hipfire" : 5.0, "recoil_rotation_ads" : 2.5,
	"recoil_position_hipfire" : 0.05, "recoil_position_ads" : 0.03,
	"recoil_camera_shake_hipfire" : 0.2, "recoil_camera_shake_ads" : 0.1,
	"max_penetrations" : 1, "penetration_damage_falloff" : 0.8},

	#smg - close range spray
	1 : {"name" : "SMG", "damage" : 18, "accuracy" : 0.65, "projectiles" : 1,
	"mag_size" : 30, "reserve_ammo" : 120, "reload_time" : 2.0,
	"is_automatic" : true, "shot_cooldown" : 0.1,
	"ads_offset" : Vector3(0.0, -0.025, -0.06), "ads_scale" : 1.2,
	"recoil_rotation_hipfire" : 4.0, "recoil_rotation_ads" : 2.0,
	"recoil_position_hipfire" : 0.04, "recoil_position_ads" : 0.02,
	"recoil_camera_shake_hipfire" : 0.15, "recoil_camera_shake_ads" : 0.08,
	"max_penetrations" : 1, "penetration_damage_falloff" : 0.7},

	#shotgun - close quarters burst
	2 : {"name" : "Shotgun", "damage" : 15, "accuracy" : 0.4, "projectiles" : 6,
	"mag_size" : 8, "reserve_ammo" : 32, "reload_time" : 2.5,
	"is_automatic" : false, "shot_cooldown" : 0.7,
	"ads_offset" : Vector3(0.0, -0.012, -0.055), "ads_scale" : 1.25,
	"recoil_rotation_hipfire" : 7.0, "recoil_rotation_ads" : 3.5,
	"recoil_position_hipfire" : 0.07, "recoil_position_ads" : 0.035,
	"recoil_camera_shake_hipfire" : 0.25, "recoil_camera_shake_ads" : 0.15,
	"max_penetrations" : 0, "penetration_damage_falloff" : 1.0},

	#sniper - long range precision (one shot headshot)
	3 : {"name" : "Sniper", "damage" : 100, "accuracy" : 0.99, "projectiles" : 1,
	"mag_size" : 5, "reserve_ammo" : 25, "reload_time" : 3.0,
	"is_automatic" : false, "shot_cooldown" : 1.2,
	"ads_offset" : Vector3(0.0, -0.01, 0.015), "ads_scale" : 1.4,
	"recoil_rotation_hipfire" : 6.0, "recoil_rotation_ads" : 3.0,
	"recoil_position_hipfire" : 0.06, "recoil_position_ads" : 0.03,
	"recoil_camera_shake_hipfire" : 0.05, "recoil_camera_shake_ads" : 0.025,
	"max_penetrations" : 5, "penetration_damage_falloff" : 0.3},

	#assault rifle - balanced all-rounder
	4 : {"name" : "Assault Rifle", "damage" : 25, "accuracy" : 0.80, "projectiles" : 1,
	"mag_size" : 30, "reserve_ammo" : 150, "reload_time" : 2.0,
	"is_automatic" : true, "shot_cooldown" : 0.12,
	"ads_offset" : Vector3(0.0, -0.008, 0.015), "ads_scale" : 1.2,
	"recoil_rotation_hipfire" : 5.0, "recoil_rotation_ads" : 2.5,
	"recoil_position_hipfire" : 0.05, "recoil_position_ads" : 0.025,
	"recoil_camera_shake_hipfire" : 0.18, "recoil_camera_shake_ads" : 0.09,
	"max_penetrations" : 2, "penetration_damage_falloff" : 0.5},

	#lmg - suppressive fire, high volume low accuracy
	5 : {"name" : "LMG", "damage" : 16, "accuracy" : 0.50, "projectiles" : 1,
	"mag_size" : 100, "reserve_ammo" : 200, "reload_time" : 3.5,
	"is_automatic" : true, "shot_cooldown" : 0.1,
	"ads_offset" : Vector3(0.0, -0.01, 0.015), "ads_scale" : 1.4,
	"recoil_rotation_hipfire" : 5.5, "recoil_rotation_ads" : 2.75,
	"recoil_position_hipfire" : 0.055, "recoil_position_ads" : 0.0275,
	"recoil_camera_shake_hipfire" : 0.22, "recoil_camera_shake_ads" : 0.11,
	"max_penetrations" : 3, "penetration_damage_falloff" : 0.4}
}

static func get_weapon_data(weapon_id) -> Dictionary:
	var data = WEAPON_DATA.get(weapon_id)
	if data == null:
		push_error("WeaponConfig: Invalid weapon_id %s" % weapon_id)
		return {}
	return data
