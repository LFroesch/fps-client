# Work Tracker

**Updated:** 2025-12-26

## Current Tasks

**P0 (Critical):**
- Solo/offline zombies mode
- Pistol-only start in zombies (must buy from walls)
- Death system: wait for next round if team alive, game over if all dead
- Grenades damage zombies

**P1 (High):**
- Add Zombie power-ups (nuke, instakill, 2x points, death machine)
- Fix Door Buying / Other Buyables System Fleshed Out / Pack-a-Punch machine / Other Upgrades
- Auto-switch zombie target to closer player
- Better AI movement/NavMesh/avoidance
- Zombie hitbox/mesh/animations/types

**P2 (Polish):**
- End-game scoreboard (points, kills)
- 
- Better downed partner indicator
- Ammo box fills both guns + current mag
- Debug commands (add points, force wave end)
- Scopes, damage range, wall bangs, sound FX, DC handling

---

## Context (AI reads this first)

**Structure:** Client (`fps-udemy-client`) + Server (`fps-udemy-server`, separate repo)
**Modes:** PvP (TDM) + Zombies (co-op waves)
**Weapons:** Pistol/SMG/Shotgun/AR/Sniper/LMG - 2-weapon inventory
**Zombies:** NavigationAgent3D AI, 3 types (Normal/Fast/Tank), wallbuys, economy

**Known Issues:** Zombie AI gets stuck w/o navmesh, grenades don't damage zombies, no offline mode

---

## Recent Changes

**Dec 26:** Reviewed docs (too verbose, need consolidation)
**Dec 24:** Simplified zombie AI, added jump animations, smart target switching
**Dec 23:** Zombie mode MVP - waves, economy, wallbuys, 2-weapon inventory
