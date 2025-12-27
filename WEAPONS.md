# Weapon System Reference

## Key Files
- `game/weapon_config.gd` - Weapon stats config
- `player/weapons/weapon.gd` - Base weapon class
- `player/weapons/weapon_holder.gd` - Instantiation
- `player/local_weapon_holder.gd` - Local shooting/reloading
- `player/local/player_local.gd` - Input/camera
- `player/weapon_inventory.gd` - 2-weapon inventory

## Weapon Config Structure
```gdscript
WeaponConfig.WEAPON_DATA[weapon_id] = {
	"name": String,
	"damage": int,
	"accuracy": float,        # 0.0-1.0
	"projectiles": int,       # Pellets per shot
	"mag_size": int,
	"reserve_ammo": int,
	"reload_time": float
}
```

## Weapon IDs
- 0 = Pistol (starter)
- 1 = SMG
- 2 = Shotgun
- 3 = Assault Rifle
- 4 = Sniper
- 5 = LMG

## Weapon Properties
```gdscript
@export var is_automatic: bool
@export var shot_cooldown: float
@export var ads_enabled: bool
@export var ads_fov_multiplier: float      # Zoom (0.6 = 60% FOV)
@export var ads_position_offset: Vector3
```

## Key Methods
```gdscript
# weapon.gd
func init_ammo() -> void
func can_shoot() -> bool
func consume_ammo() -> void
func reload() -> void
func play_shoot_fx(is_local: bool) -> void

# local_weapon_holder.gd
func shoot() -> void
func start_reload() -> void
func add_weapon_to_inventory(weapon_id: int)
func switch_to_weapon(weapon_id: int)

# weapon_inventory.gd
func add_weapon(weapon_id: int) -> Dictionary
func switch_weapon() -> void
func has_weapon(weapon_id: int) -> bool
```

## Constants
```gdscript
normal_speed = 4.0
sprint_speed = 8.0
mouse_sensitivity = 0.005
ads_mouse_sensitivity = 0.002
RECOIL_TWEEN_TIME = 0.2
Head position: (0, 1.2, 0)
LocalWeaponHolder scale: 0.05
```
