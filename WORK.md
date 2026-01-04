# Work Tracker

**Updated:** 2026-01-03

---

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
