class_name UpgradeVisualConfig

# Visual effect configuration for weapon upgrades
# Supports per-weapon, per-tier customization

const UPGRADE_VISUALS := {
	# Sniper (weapon_id: 3)
	3: {
		1: {
			"trail_enabled": true,
			"trail_color": Color(0.0, 0.8, 1.0, 0.2),  # Cyan - more transparent
			"trail_width": 0.08,
			"trail_lifetime": 1.0,  # Increased from 0.3 to 0.6
			"trail_glow": 2.0,
			"muzzle_particle_scale": 1.5,
			"muzzle_light_energy": 0.15,
			"muzzle_light_color": Color(0.0, 0.8, 1.0)
		},
		2: {
			"trail_enabled": true,
			"trail_color": Color(0.0, 0.9, 1.0, 0.2),  # More transparent
			"trail_width": 0.1,
			"trail_lifetime": 1.5,  # Increased from 0.4 to 0.7
			"trail_glow": 3.0,
			"muzzle_particle_scale": 2.0,
			"muzzle_light_energy": 0.2,
			"muzzle_light_color": Color(0.0, 0.9, 1.0)
		},
		3: {
			"trail_enabled": true,
			"trail_color": Color(0.2, 1.0, 1.0, 0.2),  # More transparent
			"trail_width": 0.12,
			"trail_lifetime": 2.0,  # Increased from 0.5 to 0.8
			"trail_glow": 4.0,
			"muzzle_particle_scale": 2.5,
			"muzzle_light_energy": 0.25,
			"muzzle_light_color": Color(0.2, 1.0, 1.0)
		},
		# Tiers 4-10 will scale progressively
	},

	# Pistol (weapon_id: 0) - Blue orb effect
	0: {
		1: {
			"trail_enabled": true,
			"trail_color": Color(0.3, 0.5, 1.0, 0.4),  # Blue - more transparent
			"trail_width": 0.08,
			"trail_lifetime": 0.25,
			"trail_glow": 2.5,
			"muzzle_particle_scale": 1.3,
			"muzzle_light_energy": 0.12,
			"muzzle_light_color": Color(0.3, 0.5, 1.0)
		},
	},

	# Shotgun (weapon_id: 2) - Orange explosive effect
	2: {
		1: {
			"trail_enabled": false,  # No trail for shotgun
			"trail_color": Color(1.0, 0.4, 0.0, 0.5),  # Orange - more transparent
			"trail_width": 0.0,
			"trail_lifetime": 0.0,
			"trail_glow": 0.0,
			"muzzle_particle_scale": 3.0,  # Big muzzle burst
			"muzzle_light_energy": 0.3,
			"muzzle_light_color": Color(1.0, 0.4, 0.0)
		},
	},

	# Assault Rifle (weapon_id: 4) - Red tracer
	4: {
		1: {
			"trail_enabled": true,
			"trail_color": Color(1.0, 0.2, 0.0, 0.4),  # Red - more transparent
			"trail_width": 0.04,
			"trail_lifetime": 0.2,
			"trail_glow": 1.5,
			"muzzle_particle_scale": 1.2,
			"muzzle_light_energy": 0.1,
			"muzzle_light_color": Color(1.0, 0.2, 0.0)
		},
	},
}

static func get_visual_config(weapon_id: int, upgrade_tier: int) -> Dictionary:
	if not UPGRADE_VISUALS.has(weapon_id):
		return {}

	var weapon_tiers = UPGRADE_VISUALS[weapon_id]

	# If exact tier config exists, use it
	if weapon_tiers.has(upgrade_tier):
		return weapon_tiers[upgrade_tier]

	# Otherwise, find the highest tier config and scale it
	var highest_tier := 0
	for tier in weapon_tiers.keys():
		if tier > highest_tier:
			highest_tier = tier

	if highest_tier == 0:
		return {}

	var base_config = weapon_tiers[highest_tier].duplicate(true)
	var tier_diff = upgrade_tier - highest_tier

	# Progressive scaling for tiers beyond defined configs
	if tier_diff > 0:
		var scale_factor = 1.0 + (tier_diff * 0.3)  # 30% increase per tier
		base_config["trail_width"] *= scale_factor
		base_config["trail_glow"] *= scale_factor
		base_config["muzzle_particle_scale"] *= scale_factor
		base_config["muzzle_light_energy"] *= scale_factor
		base_config["trail_lifetime"] = minf(base_config["trail_lifetime"] * scale_factor, 1.0)  # Cap at 1s

		# Make color brighter for higher tiers
		var color: Color = base_config["trail_color"]
		color.v = minf(color.v * scale_factor, 1.0)
		base_config["trail_color"] = color

	return base_config

static func has_visual_upgrade(weapon_id: int, upgrade_tier: int) -> bool:
	return not get_visual_config(weapon_id, upgrade_tier).is_empty()
