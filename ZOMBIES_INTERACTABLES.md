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

**Design:** Zombies have ~15% total chance to drop power-up on death

#### Power-Up Types & Drop Rates

| Power-Up | Effect | Drop Rate | Duration |
|----------|--------|-----------|----------|
| **Max Ammo** | Refill all weapons + grenades | 4% | Instant |
| **Insta-Kill** | One-hit kills | 2.5% | 30s |
| **Double Points** | 2x point earnings | 4% | 30s |
| **Nuke** | Kill all zombies (50pts each) | 1.5% | Instant |
| **Health** | Restore 75 HP | 2% | Instant |
| **Ammo** | Refill current weapon | 1.5% | Instant |

**Total:** 15.5% drop chance (roughly 1 in 7 zombies)
**Note:** Carpenter removed for now (barrier repair needs design work)

#### Power-Up Mechanics

**Despawn Timer:**
- Uncollected power-ups despawn after 30 seconds
- Visual warning: Flash/pulse effect during last 5 seconds
- Creates urgency and prevents map clutter

**Timed Power-Ups (Insta-Kill, Double Points):**
- Duration: 30 seconds from collection
- HUD indicator: Icon + countdown timer
- Visual feedback: Screen border tint or weapon glow
- Stacking: Collecting same power-up refreshes duration (doesn't stack multiplier)

**Instant Power-Ups:**
- **Max Ammo:** Refills ALL equipped weapons + grenades (magazine + reserve)
- **Nuke:** Kills all living zombies, awards 50pts each (reduced from normal kill rewards)
- **Health/Ammo:** Standard pickup behavior (75 HP / refill current weapon)

#### Implementation Plan

**Server-side (`fps-udemy-server/server/lobby.gd`):**
```gdscript
# Centralized drop table (easy tuning)
const ZOMBIE_DROP_TABLE := {
	"max_ammo":      {"chance": 0.04,  "pickup_type": 3},
	"insta_kill":    {"chance": 0.025, "pickup_type": 4},
	"double_points": {"chance": 0.04,  "pickup_type": 5},
	"nuke":          {"chance": 0.015, "pickup_type": 6},
	"health":        {"chance": 0.02,  "pickup_type": 0},
	"ammo":          {"chance": 0.015, "pickup_type": 2}
}

const POWERUP_DURATION := 30.0  # Timed effects (Insta-Kill, Double Points)
const POWERUP_DESPAWN_TIME := 30.0  # Pickup lifetime before auto-remove
```

**Changes needed:**
1. Replace `zombie_died()` drop logic (currently 60% rate) with weighted table roll
2. Add despawn timer to spawned pickups (both server + client sync)
3. Track active power-ups per lobby: `{"insta_kill": 0.0, "double_points": 0.0}`
4. Modify damage calc for insta-kill, point awards for double points
5. Broadcast `s_powerup_activated(type, duration)` and `s_powerup_expired(type)` RPCs

**Client-side (`fps-udemy-client`):**
- `player/pickups/pickup.gd`: Add flash shader in last 5 seconds before despawn
- `ui/hud/powerup_indicator.gd/tscn`: NEW - HUD overlay for active buffs
- Particle effects on power-up collection

**Files to create/modify:**
- ✅ `server/lobby.gd`: Drop table, power-up state tracking, effect logic
- ✅ `player/pickups/pickup.gd` (both repos): Despawn timer, flash warning, colored emissive boxes
- ✅ `ui/hud/hud_manager.gd`: Power-up indicators with real-time countdown timers (top-right display)

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

### 5. Wave Modifiers (Roguelike Elements)

**Design:** Random events/modifiers that trigger on specific waves to add variety and replayability

#### Special Wave Types

| Wave Type | Frequency | Description |
|-----------|-----------|-------------|
| **Boss Wave** | Every 5 waves | 3-5 Tank zombies spawn, 2x point rewards |
| **Sprint Wave** | Random 15% | All zombies are Fast type, move 1.5x faster than normal |
| **Horde Wave** | Random 10% | 2x zombie count, but each worth 50% points |
| **Hellhounds** | Every 7 waves | NEW enemy type: Fast, low HP, high damage, spawn in packs |
| **Fog Wave** | Random 8% | Reduced view distance, zombies harder to see |
| **Mini-Boss** | Waves 10, 20, 30... | Single mega-zombie with 3x Tank HP, unique abilities |

#### Environmental Modifiers (Per Wave)

**Positive Modifiers (15% chance):**
- **Fire Sale:** Mystery Box costs 10pts for this wave only
- **Bonus Points:** All zombie kills worth 2x points
- **Ammo Rain:** 3 Max Ammo power-ups spawn at random locations
- **Double Drops:** Power-up drop rate doubled (30% instead of 15%)

**Negative Modifiers (10% chance):**
- **Budget Cuts:** All wallbuys/doors cost 1.5x this wave
- **Tough Skin:** All zombies have +50% HP
- **Sprinters:** All zombies move 25% faster
- **No Perks:** Perk machines disabled this wave

**Neutral/Mixed (5% chance):**
- **Chaos Mode:** Random weapon spawns in players' hands every 15s (can't control loadout)
- **Low Gravity:** Zombies jump higher, player movement floatier
- **One in the Chamber:** Only pistols work, but every headshot = instant kill

#### Implementation Approach

**Current System Review (`wave_manager.gd`):**
- ✅ Basic wave scaling: 5 base + 3 per wave
- ✅ Zombie type distribution by wave number
- ✅ Wave break timer (currently 1s debug, normally 10s)
- ✅ Round-robin spawn point distribution

**Changes for Wave Modifiers:**
```gdscript
# In WaveManager
var current_modifier : Dictionary = {}  # {"type": "sprint_wave", "multiplier": 1.5}

func start_next_wave() -> void:
	current_wave += 1

	# Roll for special wave type
	current_modifier = determine_wave_modifier()

	# Apply modifier to spawn logic
	var zombie_count_multiplier = current_modifier.get("count_mult", 1.0)
	var zombie_speed_multiplier = current_modifier.get("speed_mult", 1.0)

	zombies_to_spawn = int((BASE_ZOMBIE_COUNT + (current_wave - 1) * ZOMBIES_PER_WAVE) * zombie_count_multiplier)

	# Broadcast modifier to clients for UI display
	lobby.s_wave_modifier_announced.rpc(current_wave, current_modifier.get("name", ""), current_modifier.get("desc", ""))

func determine_wave_modifier() -> Dictionary:
	# Boss waves every 5
	if current_wave % 5 == 0:
		return {"type": "boss", "name": "Boss Wave", "desc": "Tanks incoming!", "force_tank": true}

	# Hellhounds every 7
	if current_wave % 7 == 0:
		return {"type": "hellhounds", "name": "Hellhounds", "desc": "The dogs are loose!"}

	# Random modifiers (weighted roll)
	var roll = randf()
	if roll < 0.15:  # Sprint wave
		return {"type": "sprint", "name": "Sprint Wave", "desc": "Fast zombies only!", "force_fast": true}
	elif roll < 0.25:  # Horde wave
		return {"type": "horde", "name": "Horde Wave", "desc": "Double zombies, half points!", "count_mult": 2.0, "points_mult": 0.5}

	return {}  # Normal wave
```

**UI Display:**
- Show wave modifier notification on HUD when wave starts
- Example: "Wave 8: SPRINT WAVE - Fast zombies only!"
- Visual effects: Screen tint, particle effects during modifier waves

**Files to modify:**
- `server/zombies_mode/wave_manager.gd`: Modifier selection + application
- `server/lobby.gd`: Point multipliers, cost modifiers
- `ui/zombies_countdown/zombies_countdown_ui.gd`: Display modifier announcements

---

### 6. Misc Interactables (Lower Priority)

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

**Phase 1 (Next - Core Systems):**
1. **Power-Up System Overhaul:**
   - Lower drop rate to ~15% (from current 60%)
   - Add new power-ups: Max Ammo, Insta-Kill, Double Points, Nuke
   - Implement 30s despawn timer with 5s flash warning
   - Add HUD indicators for active timed power-ups
2. **Mystery Box:**
   - Weighted random weapon selection
   - Moves after 8 uses / teddy bear
   - Animation + sound effects

**Phase 2 (Wave Variety):**
3. **Wave Modifiers:**
   - Boss waves every 5 (Tank zombies only)
   - Random modifiers: Sprint, Horde, Fog (15-20% chance)
   - UI announcements for wave types
4. **Additional Zombie Types:**
   - Hellhounds (fast, low HP, pack spawn)
   - Mini-bosses (waves 10, 20, 30...)

**Phase 3 (Advanced Mechanics):**
5. **Additional Perks:** Electric Cherry, Vulture Aid, PhD Flopper, Widow's Wine
6. **Traps:** Electric, Fire (1000pts, 30s duration, 60s cooldown)
7. **Misc Interactables:** Teleporters, Shield system, Power Switch

**Phase 4 (Meta-Progression):**
8. **Unlock System:** Vial currency, starting weapon/perk/points unlocks
9. **Challenges:** Daily/weekly contracts for variety
10. **Leaderboards:** High wave, total kills, fastest wave clear

---

## Testing Checklist

**Mystery Box:**
- [ ] Weighted randomization works correctly
- [ ] Box moves after 8 uses
- [ ] Teddy bear triggers instant move
- [ ] Animation plays smoothly
- [ ] Syncs across all clients

**Power-Ups:**
- [ ] Drops appear at correct rate (~15% total)
- [ ] Power-ups despawn after 30 seconds
- [ ] Flash/pulse warning during last 5 seconds before despawn
- [ ] Max Ammo refills all weapons + grenades
- [ ] Insta-Kill one-shots zombies for 30s (HUD timer shows)
- [ ] Double Points multiplies earnings correctly for 30s (HUD timer shows)
- [ ] Nuke kills all zombies + awards 50pts each
- [ ] HUD indicators show active timed power-ups with countdown
- [ ] Collecting same power-up refreshes duration (doesn't stack)

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

## Meta-Progression / Roguelike Elements (Future)

**Design:** Persistent progression across runs to give long-term goals

### Option A: Bank System (Simple)
- Deposit points into "bank" during match (costs 10% fee)
- Banked points persist after game over
- Start next run with banked points
- Max bank capacity: 10,000pts

**Pros:** Simple, encourages risk/reward decisions
**Cons:** Could trivialize early waves

### Option B: Unlock System (CoD Zombies style)
- Earn "Vials" (meta-currency) based on wave reached:
  - Wave 10: 1 Vial
  - Wave 20: 3 Vials
  - Wave 30+: 5 Vials
- Spend Vials to unlock:
  - Starting weapons (500 Vials: Start with SMG)
  - Starting perks (800 Vials: Spawn with QuickRevive)
  - Starting points (300 Vials: Begin with 2000pts)
  - Permanent upgrades (1000 Vials: +10% damage forever)

**Pros:** Feels rewarding, doesn't break early game balance
**Cons:** Requires persistent save system

### Option C: Skill Tree (Deep RPG)
- Gain XP based on: Kills, headshots, wave reached, doors opened
- Level up → Skill points
- Skill trees:
  - **Offense:** +Damage, +Fire Rate, +Crit Chance
  - **Defense:** +HP, +Speed, +Armor
  - **Economy:** +Points per kill, Cheaper wallbuys, Chance for free ammo
  - **Utility:** +Grenade capacity, Faster revives, See power-up outlines

**Pros:** High replay value, build variety
**Cons:** Complex to balance, could create power creep

### Option D: Challenges/Contracts (Daily/Weekly)
- Daily Challenges:
  - "Get 50 headshots" → 500 Vials
  - "Open 5 doors" → 200 Vials
  - "Reach wave 15" → 1000 Vials
- Contract System (active during match):
  - "Kill 10 zombies with melee" → Free Max Ammo
  - "Don't take damage for 2 waves" → Free Perk
  - "Spend 0 points for 1 wave" → 2x points next wave

**Pros:** Encourages varied playstyles, adds replayability
**Cons:** Needs UI for challenge tracking

### Recommended Approach
**Phase 1:** Implement Option B (Unlock System) - clean, proven design
**Phase 2:** Add Option D (Challenges) for daily variety
**Phase 3:** Consider Option C (Skill Tree) if game has large playerbase

**Implementation Files:**
- `server/meta_progression.gd`: Track Vials, unlocks, save/load
- `ui/meta_progression_menu.tscn`: Unlock shop UI
- `server/challenge_system.gd`: Daily/weekly challenges
- Save data: JSON file or SQLite database

---

## Notes

- **Focus on fun factor:** Mystery box + power-ups add excitement/variety
- **Balance costs:** Mystery box (950) cheaper than direct weapon buys to encourage gambling
- **Visual feedback:** All interactables need clear prompts + animations
- **Server-authoritative:** All purchases/activations validated server-side
- **Placeholder art OK:** Use colored cubes/basic meshes initially
- **Wave Modifiers:** Start simple (Boss waves every 5), expand with random modifiers later
- **Meta-Progression:** Unlock system provides long-term goals without breaking early game balance
