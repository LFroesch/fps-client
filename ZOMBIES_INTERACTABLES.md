# Zombies Interactables Roadmap

Clean implementation plan for zombies mode buyables and mechanics.

---

## Current State (Implemented)

✅ **Buyables Base System** (`buyable_base.gd`)
✅ **Weapon Wallbuys** - Buy weapons/ammo, weapon-specific costs
✅ **Doors** - Collision barriers, open animations
✅ **Weapon Forge** - Multi-tier upgrades (Tier 1-3, 5k per tier)
✅ **Perk Machines** - 8 perks implemented:
- TacticalVest (2500) - 2x HP [SERVER-SIDE]
- FastHands (3000) - 1.5x reload speed
- RapidFire (2000) - 1.33x fire rate
- CombatMedic (1500) - 1.75x revive speed
- Endurance (2000) - 1.25x movement speed
- Marksman (1500) - 1.5x headshot damage [SERVER-SIDE]
- BlastShield (2500) - Explosive immunity
- HeavyGunner (4000) - 3 weapon slots

---

## Next Priorities

### 1. Mystery Box (HIGH PRIORITY)

**Design:**
- 950pts per spin
- Random weapon from pool (weighted odds)
- Box moves after 8 uses
- 5% teddy bear = instant move

**Weapon Pool:**
```gdscript
var weapon_pool = [
	{"id": 0, "weight": 5},   # Pistol (rare from box)
	{"id": 1, "weight": 30},  # SMG (common)
	{"id": 2, "weight": 25},  # Shotgun
	{"id": 3, "weight": 20},  # AR
	{"id": 4, "weight": 10},  # Sniper (rare)
	{"id": 5, "weight": 15},  # LMG
	# Future: Wonder weapons (1-2% chance)
]
```

**Behavior:**
1. Player pays 950pts → Box lid opens
2. Weapons cycle rapidly (3s animation)
3. Lands on weighted-random weapon
4. Player picks up (replaces current weapon)
5. After 8 uses → Box disappears, spawns at random location

**Server Logic:**
- Track `mystery_box_uses` per box instance
- Generate random weapon using weighted selection
- Broadcast `s_mystery_box_result(weapon_id, box_id)`
- Relocate box when uses hit limit

**File:** `player/buyables/mystery_box.gd/tscn`

---

### 2. Power-Ups (Zombie Drops)

**Design:** Zombies have 5-10% chance to drop power-up on death (30s duration)

| Power-Up | Effect | Drop Rate |
|----------|--------|-----------|
| **Max Ammo** | Refill all weapons + grenades | 8% |
| **Insta-Kill** | One-hit kills for 30s | 6% |
| **Double Points** | 2x point earnings for 30s | 10% |
| **Nuke** | Kill all zombies (400pts each) | 4% |
| **Carpenter** | Repair barriers (200pts) | 5% |

**Implementation:**
- SERVER: `spawn_powerup(type, position)` on zombie death
- CLIENT: Pickup area → `c_collect_powerup(type)`
- SERVER: Broadcast `s_powerup_activated(type, duration)` to all players
- CLIENT: HUD icon showing active power-up + timer
- Timed power-ups auto-expire after 30s

**Files:**
- `player/pickups/powerup.gd/tscn`
- `ui/hud/powerup_indicator.gd` (HUD overlay)

---

### 3. Additional Perks

**Expand beyond current 8 perks:**

| Perk | Cost | Effect |
|------|------|--------|
| **Electric Cherry** | 2000 | Electric burst on reload (damages nearby zombies) |
| **Vulture Aid** | 3000 | See zombies through walls (outline shader) |
| **PhD Flopper** | 3000 | Explosive dive attack (hold crouch while falling) |
| **Widow's Wine** | 4000 | Melee/grenades slow zombies (web effect) |
| **Tombstone** | 2000 | Keep 1 weapon on death |
| **Deadshot** | 2500 | Auto-aim headshots (subtle assist) |

**Implementation Notes:**
- Electric Cherry: AOE damage in 3m radius on reload
- Vulture Aid: Add outline material to zombies, visible through walls
- PhD Flopper: Detect fall velocity, spawn explosion on land
- Widow's Wine: Apply slow debuff on grenade/melee hit

---

### 4. Traps

**Design:** Activate for 1000pts, 30s duration, kills zombies in area

| Trap Type | Cost | Effect |
|-----------|------|--------|
| **Electric Trap** | 1000 | Electrocutes zombies in hallway |
| **Fire Trap** | 1000 | Flames kill zombies crossing |
| **Spike Wall** | 1250 | Rotating blades in doorway |
| **Turbine Fan** | 1500 | Launches zombies off ledge |

**Behavior:**
1. Player activates trap → 1000pts deducted
2. Trap plays animation (sparks, fire, etc.)
3. Zombies in trigger area take damage/die
4. 30s duration → 60s cooldown before reactivation

**Implementation:**
- SERVER: `Area3D` damage zone, `is_active` state
- CLIENT: Play particle effects + sound
- SERVER: Broadcast `s_trap_activated(trap_id)` to sync visuals

**File:** `player/buyables/trap_buyable.gd/tscn`

---

### 5. Misc Interactables (Lower Priority)

**Teleporters:**
- Link two pads (A → B)
- 1500pts to activate, 10s cooldown
- Instant travel across map

**Ammo Crates:**
- 4500pts to refill ALL weapons (expensive but convenient)
- Alternative to wallbuys

**Shield Crafting:**
- Collect 3 parts scattered in map
- 1500pts to assemble at workbench
- Blocks zombie hits from behind, breaks after X hits

**Power Switch:**
- Free to activate (one-time)
- Enables all electric buyables/perks/traps in area
- Map-specific (e.g., "Turn on Generator")

---

## Implementation Priority

**Phase 1 (Next):**
1. Mystery Box (core mechanic, high replay value)
2. Power-Ups (Insta-Kill buff 60 sec or something, Double Points 60 sec or something, Nuke, more?)

**Phase 2:**
3. 3-4 Additional Perks (Electric Cherry, Vulture Aid, PhD Flopper)
4. Traps (Electric, Fire)

**Phase 3:**
5. Teleporters
6. Shield system
7. Power Switch (map-specific)

---

## Testing Checklist

**Mystery Box:**
- [ ] Weighted randomization works correctly
- [ ] Box moves after 8 uses
- [ ] Teddy bear triggers instant move
- [ ] Animation plays smoothly
- [ ] Syncs across all clients

**Power-Ups:**
- [ ] Drops appear at correct rate (5-10%)
- [ ] Max Ammo refills all weapons + grenades
- [ ] Insta-Kill one-shots zombies for 30s
- [ ] Double Points multiplies earnings correctly
- [ ] Nuke kills all zombies + awards points
- [ ] HUD icon shows active power-up + timer

**Perks:**
- [ ] Electric Cherry damages zombies on reload
- [ ] Vulture Aid highlights zombies through walls
- [ ] PhD Flopper detects falls and creates explosion
- [ ] All perks stack with existing 8 perks

**Traps:**
- [ ] Activation costs 1000pts
- [ ] Zombies in trigger area die
- [ ] 30s duration + 60s cooldown
- [ ] Visuals sync across clients
- [ ] Cannot activate while on cooldown

---

## Notes

- **Focus on fun factor:** Mystery box + power-ups add excitement/variety
- **Balance costs:** Mystery box (950) cheaper than direct weapon buys to encourage gambling
- **Visual feedback:** All interactables need clear prompts + animations
- **Server-authoritative:** All purchases/activations validated server-side
- **Placeholder art OK:** Use colored cubes/basic meshes initially
