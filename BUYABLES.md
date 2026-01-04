# Zombie Mode Buyables Reference

Quick reference for implemented buyables system.

---

## Architecture

**Base Class:** `player/buyables/buyable_base.gd`
- All buyables extend this for consistency
- Handles interaction area, prompts, purchase flow
- Override `on_purchase_requested()` in child classes

**Key Properties:**
- `cost`, `buyable_id`, `buyable_name`, `prompt_text`
- `one_time_purchase` (doors), `is_purchased`
- `interact_range` (default 2.0m)

---

## Implemented Buyables

### 1. Weapon Wallbuys ✅
**File:** `player/buyables/weapon_wallbuy.gd/tscn`

**Status:** Fully working
- Weapon-specific costs (Pistol free, SMG 1k, Shotgun 1.5k, AR 2k, LMG 2.5k, Sniper 3k)
- Ammo refills (500-1000pts depending on weapon)
- Hold-to-confirm for ammo purchases
- Only refills reserve ammo for that specific weapon
- Visual weapon display in editor

---

### 2. Doors ✅
**File:** `player/buyables/door_buyable.gd/tscn`

**Status:** Fully working
- Multiple door types: Slide, Swing, Roll, Debris
- Configurable cost per door (default 750)
- Animation on purchase
- Collision disabled after opening
- Syncs across all clients

---

### 3. Weapon Forge ✅
**File:** `player/buyables/weapon_forge.gd/tscn`

**Status:** Multi-tier upgrades working
- 5000pts per tier (Tier 1 → 2 → 3)
- Per-tier bonuses:
  - Tier 1: +50% reserve, +33% mag, +25% damage
  - Tier 2: +100% reserve, +66% mag, +50% damage
  - Tier 3: +150% reserve, +99% mag, +75% damage
- Can re-upgrade up to max tier (default 3)
- Per-weapon-instance upgrades (each purchase is fresh)
- Cannot upgrade grenades

---

### 4. Perk Machines ✅
**File:** `player/buyables/perk_machine.gd/tscn`

**Status:** 8 perks implemented

| Perk | Cost | Effect | Server-Side |
|------|------|--------|-------------|
| TacticalVest | 2500 | 2x HP (100→200) | ✅ |
| FastHands | 3000 | 1.5x reload speed | Client |
| RapidFire | 2000 | 1.33x fire rate | Client |
| CombatMedic | 1500 | 1.75x revive speed | Client |
| Endurance | 2000 | 1.25x movement speed | Client |
| Marksman | 1500 | 1.5x headshot damage | ✅ |
| BlastShield | 2500 | Explosive immunity | Client |
| HeavyGunner | 4000 | 3 weapon slots | ✅ |

- Each player can buy multiple different perks
- Perks lost on death
- HUD display shows active perks

---

## RPC Flow

**Client → Server:**
- `c_try_buy_weapon(weapon_id, is_ammo)`
- `c_try_buy_door(door_id)`
- `c_try_upgrade_weapon(weapon_id)`
- `c_try_buy_perk(perk_type)`

**Server → Client:**
- `s_weapon_purchased(weapon_id, is_ammo)`
- `s_door_opened(door_id)`
- `s_weapon_upgraded(weapon_id)`
- `s_perk_purchased(perk_type)`
- `s_purchase_failed(reason)`
- `s_update_player_points(points)`

---

## File Structure

```
player/buyables/
├── buyable_base.gd/tscn       ✅
├── weapon_wallbuy.gd/tscn     ✅
├── door_buyable.gd/tscn       ✅
├── weapon_forge.gd/tscn       ✅
├── perk_machine.gd/tscn       ✅
└── grenade_buyable.gd         🚧 In progress

ui/hud/
└── hud_manager.gd             ✅ (perk display)
```

---

## Pricing Reference

| Item | Cost | Notes |
|------|------|-------|
| **Weapons** | | |
| Pistol | Free | Starting weapon |
| SMG | 1000 | Ammo: 500 |
| Shotgun | 1500 | Ammo: 500 |
| AR | 2000 | Ammo: 750 |
| LMG | 2500 | Ammo: 750 |
| Sniper | 3000 | Ammo: 1000 |
| **Upgrades** | | |
| Weapon Forge | 5000/tier | 3 tiers max |
| **Perks** | | |
| CombatMedic | 1500 | Revive speed |
| Marksman | 1500 | Headshot damage |
| RapidFire | 2000 | Fire rate |
| Endurance | 2000 | Movement speed |
| TacticalVest | 2500 | 2x HP |
| BlastShield | 2500 | Explosive immunity |
| FastHands | 3000 | Reload speed |
| HeavyGunner | 4000 | 3 weapons |
| **Doors** | 750-2000 | Configurable |

---

## Next Steps

See **ZOMBIES_INTERACTABLES.md** for:
- Mystery Box implementation
- Power-Ups (Max Ammo, Insta-Kill, Nuke, etc.)
- Additional perks
- Traps/teleporters

---

## Notes

- All purchases validated server-side
- Server broadcasts to all clients for sync
- Client-side uses `get_tree().call_group("Lobby", ...)` pattern
- Placeholder meshes (colored boxes) currently used
