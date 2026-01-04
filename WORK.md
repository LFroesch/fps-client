# Work Tracker

**Updated:** 2026-01-03

---

- Weapon Forge / Upgraded weapon changes / bullets / etc
- more gun options
- test new perks
- zombie scaling
- roguelike buffs/drops
- split up big files / clean up systems / etc

## Current Tasks

**P0 (Critical):**
- [ ] Build out more test maps / prototype for testing etc
- [ ] Figure out the multi player names issues? could just be because dual booting em
- [ ] Solo/offline zombies mode
- [ ] Fix spectator camera (see FUTURE.md)

**P1 (High - Next Sprint):**
- [ ] **Mystery Box** (see ZOMBIES_INTERACTABLES.md)
- [ ] **Power-Ups:** Max Ammo, Insta-Kill, Double Points, Nuke, Carpenter
- [ ] Zombie visuals (proper hitbox, mesh, animations, types)

**P2 (Polish):**
- [ ] Better downed partner indicator
- [ ] Debug commands (add points, force wave end, spawn zombies)
- [ ] Scopes, damage range, wall penetration / upgrade effects
- [ ] Sound FX, disconnect handling

**External:**
- [ ] Submit Godot PR: Auto-save NavigationMesh after baking (prevents "appears baked but not persisted" bug)

---

## Zombies Roadmap

See **ZOMBIES_INTERACTABLES.md** for detailed plans:

**Phase 1 (Next):**
1. Mystery Box (random weapons, moves after 8 uses, teddy bear)
2. Power-Ups (zombie drops with timed effects)

**Phase 2:**
3. Additional Perks (Electric Cherry, Vulture Aid, PhD Flopper, Widow's Wine)
4. Traps (Electric, Fire, Spike Wall, Turbine)

**Phase 3:**
5. Advanced mechanics (teleporters, shield system, power switch)
6. Wonder Weapons (map-specific special weapons)
7. Wave Modifiers (boss rounds, fog, sprinters)

**Future Ideas (Brainstorm):**
- Multi-tier weapon system (elemental effects, Pack-a-Punch transformations)
- Alt-fire modes (charge shot, slug toggle, breath holding)
- Meta progression (bank, persistent upgrades, challenges)
- Easter eggs (map-specific quests)

---

## Context (AI Reference)

**Structure:** Client (`fps-udemy-client`) + Server (`fps-udemy-server`, separate repo)
**Modes:** PvP (TDM) + Zombies (co-op waves)
**Weapons:** Pistol/SMG/Shotgun/AR/Sniper/LMG - 2-weapon inventory (3 with HeavyGunner)
**Zombies:** NavigationAgent3D AI, 3 types (Normal/Fast/Tank), wallbuys, economy

**Known Issues:**
- No offline mode (server-based solo only)

---

## DevLog (Recent Changes)

**Jan 4 2026:**
- v20.2: Fixed insta-kill damage points exploit (capped to zombie max_health), pickup rotation error, zombie death race condition, pickup flash warning (replaced async loop with repeating Timer), duplicate drops (zombie_id randomization)
- v20.1: Rebalanced zombie drop rates - Max Ammo (7%), Double Points (5%), Health (3%), Insta-Kill (1.5%), Nuke (0.5%) - total ~17% drop chance
- v20: Power-Up System Overhaul (Phase 1) - COMPLETE
  - Reduced zombie drop rate from 60% to ~17% (tunable via `ZOMBIE_DROP_TABLE` constant)
  - New power-ups: Max Ammo, Insta-Kill, Double Points, Nuke, Health
  - 30s despawn timer for uncollected power-ups with 5s flash warning
  - Server: Insta-kill (9999 damage), Double Points (2x multiplier), Nuke (kills all, 50pts each), Max Ammo (refills all + grenades)
  - Power-up state tracking with Timer-based expiration (30s duration for timed buffs)
  - **Visuals:** Colored emissive boxes (Red=Insta-Kill, Gold=Double Points, Green=Nuke) with rotating animation
  - **HUD:** Top-right power-up indicators with real-time countdown timers (updates every frame)
  - Client: Flash warning effect, RPC handlers, full HUD implementation
  - Files: `server/lobby.gd`, `player/pickups/pickup.gd` (both repos), `ui/hud/hud_manager.gd`
- v19: Weapon upgrade visual effects system
  - Created modular UpgradeVisualConfig for per-weapon, per-tier visual customization
  - Bullet trails for upgraded weapons (cyan laser for sniper, configurable colors/sizes)
  - Tier-based muzzle flash scaling (brightness, particle count, color tinting)
  - Server: Fixed get_player_weapon_stats() to use tier-based multipliers (was boolean)
  - Client: s_spawn_bullet_trail RPC spawns BulletTrail mesh with fade-out
  - Supports progressive scaling: tier 1 = subtle glow, tier 5+ = intense beam

**Jan 3 2026:**
- v18: Health bar now shows actual HP values (100/100) instead of normalized (1/1)
- v17: Fixed HeavyGunner perk - now correctly allows 3 weapons
- v16: SERVER-side perks implemented (TacticalVest 2x HP, Marksman 1.5x headshot damage)
- v15: Added HP label to health bar, repositioned ammo HUD element
- v14: Fixed buyable bugs (weapon-specific costs, grenade prevention, multi-player perk purchases)
- v13: Multi-tier weapon upgrades working server-side (tier tracking per weapon)
- v12: Client multi-tier upgrades + additive scaling per tier
- v11: Fixed upgrade system - per-weapon-instance upgrades (CoD Zombies behavior)
- v10: Weapon system overhaul - damage/switching/upgrades all synced properly
- v9: Weapon name displayed in ammo HUD
- v8-v1: Various buyables fixes (metadata, prompts, perks, doors)

**Jan 2:**
- Fixed buyables system + purchase feedback
- Visual overhaul (Label3D, weapon models in editor)
- Editor UX improvements (@tool directive, colored placeholder meshes)
- Improved zombie pathfinding (randomized recalc times, jump point fixes)

**Jan 1:**
- Fixed static map pickups in zombie mode
- Fixed zombie drop visuals
- Auto-forward toggle (middle mouse)

**Dec 31:**
- Fixed grenades physics (lobby physics space assignment)
- Shot forgiveness system (0.25u horizontal radius)
- Buyables core polish (hold-to-confirm, collision fixes)

**Dec 30:**
- **CRITICAL FIX:** Multi-lobby zombie floating bug (100+ hours debugging) - separate physics spaces per lobby

**Dec 27:**
- UX overhaul (lobby browser, waiting room UI)
- Fixed matchmaking, zombie spawns, navigation
- Implemented all 8 perk effects
- Server/client RPC synchronization fixes

**Dec 26:**
- Buyables implementation (base class, wallbuys, doors, forge, perks)
- Death/spectator/respawn system
- Pistol-only start in zombies
- Grenades damage zombies
- Zombie HUD redesign

**Dec 23-24:**
- Zombie mode MVP (waves, economy, wallbuys, inventory)
- Simplified zombie AI, jump animations, target switching
