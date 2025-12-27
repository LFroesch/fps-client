# Zombie Mode Buyables System

## Architecture

### Base Class: `buyable_base.gd`
All buyables extend this class for consistency and easy expansion.

```gdscript
class_name BuyableBase extends Node3D

@export_group("Buyable Settings")
@export var buyable_id: String = ""
@export var cost: int = 1000
@export var buyable_name: String = "Item"
@export var prompt_text: String = "Press F to buy"
@export var one_time_purchase: bool = false

@export_group("Interaction")
@export var interact_range: float = 2.0

var is_purchased: bool = false
var interact_area: Area3D
var player_nearby: PlayerLocal = null

func _ready() -> void:
	setup_interaction_area()
	setup_visuals()

func setup_interaction_area() -> void:
	interact_area = Area3D.new()
	interact_area.collision_layer = 0
	interact_area.collision_mask = 2
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(interact_range * 2, interact_range * 2, interact_range * 2)
	collision.shape = shape
	interact_area.add_child(collision)
	add_child(interact_area)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func setup_visuals() -> void:
	pass  # Override in child classes

func _on_body_entered(body: Node3D) -> void:
	if body is PlayerLocal:
		player_nearby = body
		update_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body == player_nearby:
		player_nearby = null
		hide_prompt()

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		attempt_purchase()

func update_prompt() -> void:
	if not can_interact():
		return
	get_tree().call_group("InteractionPrompt", "show_prompt", get_prompt_text())

func hide_prompt() -> void:
	get_tree().call_group("InteractionPrompt", "hide_prompt")

func get_prompt_text() -> String:
	return "%s\nCost: %d points" % [prompt_text, cost]

func can_interact() -> bool:
	if one_time_purchase and is_purchased:
		return false
	return true

func attempt_purchase() -> void:
	if not can_interact():
		return
	on_purchase_requested()

func on_purchase_requested() -> void:
	pass  # Override in child classes

func on_purchase_success() -> void:
	is_purchased = true
	hide_prompt()

func on_purchase_failed(reason: String) -> void:
	# Show error feedback
	pass
```

---

## 1. Weapon Wallbuys

### Current Issues
- ❌ No confirmation when buying ammo
- ❌ Refills ALL weapons, not just the one you're buying ammo for
- ❌ Can't tell if you already own the weapon

### Improved System

**Class:** `weapon_wallbuy.gd extends BuyableBase`

**Features:**
- Show weapon display (already works)
- Detect if player owns weapon
- **NEW:** Confirmation dialog for ammo purchase
- **NEW:** Only refill ammo for THIS weapon
- Visual feedback (glow when owned)

**Properties:**
```gdscript
@export var weapon_id: int = 1
@export var weapon_cost: int = 1000
@export var ammo_cost: int = 500
var weapon_display: Node3D
```

**Behavior:**
1. Player approaches → check inventory
2. If NO weapon → "Press F to buy [Weapon] - [cost]"
3. If HAS weapon → "Press F to refill ammo - [ammo_cost] (Hold F to confirm)"
4. On purchase:
   - If new weapon → `get_tree().call_group("Lobby", "try_buy_weapon", weapon_id, false)`
   - If ammo → Show confirmation UI, then `try_buy_weapon(weapon_id, true)`

**Ammo Refill Logic:**
- Server receives `is_ammo=true` flag
- Client receives `s_weapon_purchased(weapon_id, is_ammo)`
- **Only refill reserve ammo for weapon_id**, not current mag, not other weapons

---

## 2. Physical Doors

### Current Issues
- ❌ Placeholder red barriers (not immersive)
- ❌ No proper door models/animations
- ❌ Simple fade-out animation

### Improved System

**Class:** `door_buyable.gd extends BuyableBase`

**Door Types:**
1. **Sliding Door** - Slides sideways
2. **Swinging Door** - Rotates open
3. **Garage Door** - Rolls up vertically
4. **Debris** - Planks/rubble vanish (CoD-style)

**Properties:**
```gdscript
@export var door_id: String = "door_1"
@export var cost: int = 750
@export_enum("Slide", "Swing", "Roll", "Debris") var door_type: String = "Slide"
@export var door_mesh: MeshInstance3D
@export var open_direction: Vector3 = Vector3.RIGHT
```

**Animation Examples:**
- **Slide:** Tween `position.x += 3.0` over 1s
- **Swing:** Tween `rotation.y += 90` over 0.8s
- **Roll:** Tween `position.y += 3.0` over 1s
- **Debris:** Particles + fade over 0.5s

**Purchase Flow:**
1. Player presses F → RPC `c_try_buy_door(door_id)`
2. Server validates → Broadcasts `s_door_opened(door_id)`
3. **ALL clients** find door by `door_id` and play open animation
4. Disable collision shape

---

## 3. Weapon Forge

### Design
Single-tier weapon upgrade system.

**Class:** `weapon_forge.gd extends BuyableBase`

**Properties:**
```gdscript
@export var upgrade_cost: int = 5000
@export var upgrade_duration: float = 3.0
var is_in_use: bool = false
```

**Behavior:**
1. Player with weapon approaches → "Press F to Upgrade Weapon - 5000"
2. Player presses F:
   - Takes current weapon
   - Shows upgrade animation (3s)
   - Returns upgraded weapon
3. Cannot use while another player is upgrading

**Weapon Upgrade Effects:**
- Damage: +50%
- Reserve ammo: +50%
- Magazine size: +33%
- Name suffix: " Mk II"
- Visual: Add glow/particle effect to weapon

**Data Structure:**
```gdscript
# In weapon_config.gd or similar
var upgraded_weapons = {
	1: { # SMG -> SMG Mk II
		"damage": 18,  # was 12
		"mag_size": 40, # was 30
		"reserve_ammo": 240 # was 160
	},
	# ... other weapons
}
```

**Server Logic:**
- Track `weapon.is_upgraded` flag per player
- On wallbuy: If already upgraded, don't allow re-upgrade
- On death: Keep upgraded weapons (or lose them, your choice)

---

## 4. Perk Machines

### Design
Per-match progression: buy perks during the game, lose on death or match end.

**Class:** `perk_machine.gd extends BuyableBase`

**Perk Types:**

| Perk | Cost | Effect |
|------|------|--------|
| **Tactical Vest** | 2500 | +100% max HP |
| **Fast Hands** | 3000 | +50% reload speed |
| **Rapid Fire** | 2000 | +33% fire rate |
| **Combat Medic** | 1500 | +75% revive speed |
| **Endurance Training** | 2000 | +25% movement speed |
| **Marksman** | 1500 | +10% damage to headshots |
| **Blast Shield** | 2500 | Immune to explosive damage |
| **Heavy Gunner** | 4000 | +1 weapon slot (3 total) |

**Properties:**
```gdscript
@export_enum("TacticalVest", "FastHands", "RapidFire", "CombatMedic", "Endurance", "Marksman", "BlastShield", "HeavyGunner") var perk_type: String = "TacticalVest"
@export var perk_color: Color = Color.RED
var machine_mesh: MeshInstance3D
```

**Behavior:**
1. Player approaches → "Press F to buy [Perk Name] - [cost]"
2. Purchase → Server tracks `player.perks[]` array
3. Apply stat modifiers (HP, speed, etc.)
4. Show perk icon in HUD
5. **On death:** Lose all perks (optional: keep one with Combat Medic)

**Visual:**
- Vending machine model (colored box for now)
- Glowing effect when available
- Gray out after purchase (if one-time)

---

## 5. Mystery Box

### Design
Gambling mechanic: spend points for random weapon.

**Class:** `mystery_box.gd extends BuyableBase`

**Properties:**
```gdscript
@export var spin_cost: int = 950
@export var spin_duration: float = 3.0
@export var move_after_uses: int = 8  # Box relocates after X uses
var uses_remaining: int = 8
var is_spinning: bool = false
```

**Weapon Pool:**
```gdscript
var weapon_pool = [
	{"id": 1, "weight": 30},  # SMG (common)
	{"id": 2, "weight": 25},  # Shotgun
	{"id": 3, "weight": 20},  # AR
	{"id": 4, "weight": 10},  # Sniper (rare)
	{"id": 5, "weight": 15}   # LMG
]
```

**Behavior:**
1. Player presses F → Pay 950 points
2. Box lid opens, weapons cycle rapidly (3s)
3. Slow down, land on random weapon (weighted)
4. Player picks up weapon (replaces current)
5. After 8 uses → Box disappears, reappears elsewhere

**Special Items (optional):**
- **Teddy Bear (5% chance):** No weapon, box moves immediately
- **Max Ammo:** Refills all weapons
- **Carpenter:** Repairs all barriers

**Animation:**
- Weapon models rotate/levitate above box
- Particle effects (lightning, glow)
- Sound cues (sting, whoosh, ding)

---

## 6. In-Match Progression System

### Design
Players level up DURING each match. Resets when game ends.

**Manager:** `match_progression_manager.gd` (autoload or in Lobby)

**XP Sources:**
| Action | XP Gained |
|--------|-----------|
| Kill normal zombie | 50 XP |
| Kill fast zombie | 75 XP |
| Kill tank zombie | 100 XP |
| Complete wave | 200 XP |
| Revive teammate | 150 XP |
| Open door | 50 XP |

**Leveling Curve:**
```gdscript
func get_xp_for_level(level: int) -> int:
	return 500 + (level * 250)  # 500, 750, 1000, 1250...
```

**Level-Up Rewards (Choose One):**

Each level, player chooses 1 of 3 random upgrades:
- **+10% Damage** (all weapons)
- **+50 Max HP**
- **+15% Movement Speed**
- **+1 Grenade Capacity**
- **-10% Reload Time**
- **+5% Sprint Speed**
- **+10% Points Earned**
- Cap these at a certain logical point and just fill with other options

**UI:**
- Progress bar in HUD
- Level-up notification
- **Choice Dialog:** Shows 3 random upgrades, click to select
- Current level display (top-right)

**Implementation:**
```gdscript
# player_local.gd or similar
var match_level: int = 0
var match_xp: int = 0
var match_upgrades = {
	"damage_mult": 1.0,
	"hp_bonus": 0,
	"speed_mult": 1.0,
	# ...
}

func add_xp(amount: int) -> void:
	match_xp += amount
	var xp_needed = get_xp_for_level(match_level + 1)
	if match_xp >= xp_needed:
		level_up()

func level_up() -> void:
	match_level += 1
	match_xp -= get_xp_for_level(match_level)
	show_upgrade_choice_ui()
```

---

## 7. Random Events / Wave Modifiers

### Design
Roguelike variety: each wave has a chance for special modifiers.

**Manager:** `wave_modifier_manager.gd` (in WaveManager)

**Modifier Types:**

| Modifier | Chance | Effect |
|----------|--------|--------|
| **Firestorm** | 10% | All zombies burn (DoT), +50% speed |
| **2x Points** | 15% | Double points this wave |
| **Boss Wave** | 5% | 3x tank zombies only |
| **Speed Demons** | 10% | All zombies +100% speed |
| **Horde** | 10% | +50% zombie count, -25% HP each |
| **Instakill** | 8% | All damage = instant kill (30s) |
| **Max Ammo** | 12% | Free ammo refill at wave start |
| **Fog** | 5% | Reduced visibility |

**Behavior:**
1. At wave start, roll for modifier (30% chance any modifier)
2. If triggered, broadcast `s_wave_modifier(modifier_type, duration)`
3. Show notification: "⚠️ FIRESTORM WAVE"
4. Apply effects to zombies/players
5. End at wave complete or timer

**Visual Feedback:**
- Screen tint (red for fire, blue for instakill)
- HUD icon showing active modifier
- Particle effects on zombies
- Audio stinger

---

## System Integration

### RPC Flow (Client ↔ Server)

**Client → Server:**
```gdscript
# Weapon purchase
c_try_buy_weapon(weapon_id: int, is_ammo: bool)

# Door purchase
c_try_buy_door(door_id: String)

# Weapon Forge
c_try_upgrade_weapon(weapon_id: int)

# Perk purchase
c_try_buy_perk(perk_type: String)

# Mystery box
c_try_spin_mystery_box(box_id: String)
```

**Server → Client:**
```gdscript
# Purchases
s_weapon_purchased(weapon_id: int, is_ammo: bool)
s_door_opened(door_id: String)
s_weapon_upgraded(weapon_id: int)
s_perk_purchased(perk_type: String)
s_mystery_box_result(weapon_id: int)
s_purchase_failed(reason: String)
s_update_player_points(points: int)

# Progression
s_add_xp(amount: int)
s_level_up(new_level: int, choices: Array)

# Events
s_wave_modifier(modifier_type: String, duration: float)
```

---

## File Structure

```
player/buyables/
├── buyable_base.gd/tscn
├── weapon_wallbuy.gd/tscn
├── door_buyable.gd/tscn
├── weapon_forge.gd/tscn
├── perk_machine.gd/tscn
├── mystery_box.gd/tscn

ui/zombie_hud/
├── match_progression_ui.gd/tscn
├── level_up_choice_dialog.gd/tscn
├── wave_modifier_hud.gd/tscn
├── perk_icons.gd/tscn

managers/ (autoload or in Lobby)
├── match_progression_manager.gd
├── wave_modifier_manager.gd
```

---

## Pricing Reference

**Weapons:**
- Pistol: Free (starting)
- SMG: 1000 / Ammo: 500
- Shotgun: 1500 / Ammo: 500
- AR: 2000 / Ammo: 750
- Sniper: 3000 / Ammo: 1000
- LMG: 2500 / Ammo: 750

**Upgrades:**
- Weapon Forge: 5000

**Perks:**
- Combat Medic: 1500
- Marksman: 1500
- Rapid Fire: 2000
- Endurance Training: 2000
- Tactical Vest: 2500
- Blast Shield: 2500
- Fast Hands: 3000
- Heavy Gunner: 4000

**Doors:**
- Early: 750
- Mid: 1000-1500
- Late: 2000+

**Misc:**
- Mystery Box: 950

---

## Implementation Priority

**Phase 1 (Core Fixes):**
1. ✅ Create this doc
2. Create `buyable_base.gd`
3. Refactor `weapon_wallbuy.gd` to extend base
4. Add ammo-only confirmation UI
5. Fix ammo refill (only target weapon)

**Phase 2 (Doors):**
6. Create `door_buyable.gd` with animation support
7. Replace current `door_barrier.gd`
8. Add door types (slide/swing/roll)

**Phase 3 (New Buyables):**
9. Implement Weapon Forge
10. Implement Perk machines (start with 3-4 perks)
11. Implement Mystery Box

**Phase 4 (Progression):**
12. Create `match_progression_manager.gd`
13. Add XP tracking + level-up UI
14. Implement upgrade choice system

**Phase 5 (Roguelike):**
15. Create `wave_modifier_manager.gd`
16. Implement 5-6 wave modifiers
17. Add visual/audio feedback

**Phase 6 (Polish):**
18. Replace placeholder meshes with models
19. Add particle effects + sounds
20. Balance testing

---

## Testing Checklist

**Weapon Wallbuys:**
- [ ] Shows "Buy weapon" when you don't own it
- [ ] Shows "Refill ammo" when you own it
- [ ] Ammo refill requires confirmation (hold F)
- [ ] Only refills reserve ammo for THAT weapon
- [ ] Doesn't refill current magazine

**Doors:**
- [ ] Physical door models animate smoothly
- [ ] Collision disables after opening
- [ ] All clients see door open simultaneously
- [ ] Door stays open permanently

**Weapon Forge:**
- [ ] Weapon upgrade increases damage/ammo
- [ ] Only one player can use at a time
- [ ] 3s upgrade animation
- [ ] Can't upgrade already-upgraded weapon

**Perks:**
- [ ] Stat boosts apply correctly
- [ ] Perk icons show in HUD
- [ ] Can buy multiple perks
- [ ] Lose all perks on death

**Mystery Box:**
- [ ] Random weapon with weighted odds
- [ ] 3s spin animation
- [ ] Box moves after 8 uses
- [ ] Teddy bear triggers immediate move

**Progression:**
- [ ] XP bar updates correctly
- [ ] Level-up shows 3 random choices
- [ ] Chosen upgrade applies to stats
- [ ] Resets to level 0 on new match

**Wave Modifiers:**
- [ ] 30% chance per wave
- [ ] Notification displays correctly
- [ ] Effects apply to zombies
- [ ] Modifier ends at wave complete

---

## Notes
- All client-side buyables use `get_tree().call_group("Lobby", "try_buy_X")` pattern
- Server validates all purchases (points, ownership, state)
- Server broadcasts results to ALL clients for sync
- Use placeholder meshes initially, replace with assets later
- Balance costs based on playtesting
