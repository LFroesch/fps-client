# Work Tracker

**Updated:** 2025-12-30

## Current Tasks

**P0 (Critical):**
- Solo/offline zombies mode
- Fix Spectator Camera
- Clean up Print Statements
- Fix weird zombie movement - if in line of sight / no obstacles / same y level move directly toward player?

**P1 (High):**
- Add Zombie power-ups (nuke, instakill, 2x points, death machine)
- Buyables System Redesign (see BUYABLES.md) - wallbuy ammo fixes, physical doors, Pack-a-Punch, perks, mystery box, in-match progression, wave modifiers
- Better AI movement/NavMesh/avoidance
- Zombie hitbox/mesh/animations/types
- Make grenade explosions bigger?

**P2 (Polish):**
- Better downed partner indicator
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
**Dec 30:** CRITICAL FIX - Multi-lobby zombie floating bug (100+ hours): Root cause was shared physics space across all lobbies. Zombies at Y=0 were colliding with floors at Y=50 from other lobbies. Solution: (1) SERVER lobby.gd - Each lobby creates unique PhysicsServer3D.space, assign_physics_space_recursive() assigns all physics bodies to lobby's space, _exit_tree() cleanup, (2) SERVER wave_manager.gd - Zombies assigned to lobby physics space on spawn, (3) Replaced all magic number game mode checks with MapRegistry.GameMode enum, (4) Added documentation comments explaining physics isolation. Navigation was working correctly - physics collision was the issue.
**Dec 27 (PM v5):** UX overhaul + debugging improvements: (1) Browse Lobbies - added PvP/Zombies tabs, 1s auto-refresh, shows both modes (browse_lobbies_ui.gd), (2) Main Menu - removed game mode toggle buttons and QuickPlay, now just Browse/Create/Join by Code (main_menu.gd/.tscn), (3) Leave lobby - server now broadcasts s_lobby_updated to remaining players when someone leaves IDLE lobby (server/lobby.gd:135-141), (4) Removed ~40 noisy debug prints from client lobby/server code, (5) Server camera - added per-lobby camera with on-screen buttons to switch between 4 lobby slots (lobby_camera_controller.gd)
**Dec 27 (PM v4):** UX Overhaul - Implemented clean lobby browser system: (1) SERVER: Added c_request_lobby_list RPC to fetch available lobbies by game mode, broadcasts s_lobby_updated to all players when someone joins, (2) CLIENT: Created browse_lobbies_ui with scrollable list showing map/host/players, real-time lobby updates via s_lobby_updated RPC, (3) CLIENT main_menu: Redesigned with PvP/Zombies tabs + Browse/Create/QuickPlay buttons (removed map grid), (4) CLIENT LocalGameSceneManager: Enhanced to support multiple activate() signatures for different UI types. Clean UX for testing!
**Dec 27 (PM v3):** CRITICAL FIXES - Fixed completely broken matchmaking and zombie systems: (1) CLIENT main_menu: Switched from old try_connect_client_to_lobby to new quick_play matchmaking system, (2) CLIENT lobby: Fixed PVP mode to remove ALL buyables (BuyableBase check instead of specific types), (3) SERVER wave_manager: Fixed zombie spawn positions using explicit coordinate conversion (lobby.to_local) instead of global_transform to prevent 100-unit offset bug in multi-lobby scenarios, (4) SERVER server: Fixed lock_lobby to use minimum player requirements (1 for Zombies, 2 for PVP) instead of requiring full lobby - this was preventing hosts from starting games!
**Dec 27 (PM v2):** Fixed multi-lobby navigation + zombie attacks: (1) CLIENT: Fixed 4 locations in lobby.gd to use local position instead of global, (2) SERVER wave_manager: Moved global_transform after add_child to fix position doubling, (3) SERVER zombie_server: Fixed attack dead zone - increased ATTACK_RANGE 0.3→1.5m, reverted nav agent distances to 0.5/0.5 and CORRIDORFUNNEL pathfinding, (4) SERVER lobby: Each lobby gets unique NavigationServer3D map to prevent cross-lobby interference, (5) SERVER wave_manager: Zombies assigned to their lobby's nav map on spawn.
**Dec 27 (AM v5):** Fixed perk crash + added door debug: (1) Fixed "max_health" crash - perks now store multipliers as metadata instead of trying to modify non-existent client-side health properties, (2) Added extensive debug output to door system (client + server) to diagnose why doors aren't opening, (3) Perks use safe property checks before modifying player stats.
**Dec 27 (AM v4):** Implemented ALL buyable effects + door fix: (1) Weapon upgrades - +50% damage/reserve ammo, +33% mag size applied instantly, (2) All 8 perk effects - TacticalVest (2x HP), FastHands (1.5x reload), RapidFire (1.33x fire rate), CombatMedic (1.75x revive), Endurance (1.25x speed), Marksman (1.1x headshot), BlastShield (explosive immunity), HeavyGunner (3 weapon slots), (3) Door fix - recursive search in Map for any door_id. Fully functional buyables system!
**Dec 27 (AM v3):** Fully implemented weapon upgrades + perks on server: (1) Weapon Forge - tracks upgraded_weapons per player, costs 5000pts, prevents re-upgrading, (2) Perk system - 8 perks with costs 1500-4000pts, tracks perks array per player, prevents duplicates, (3) Client handlers for s_weapon_upgraded/s_perk_purchased RPCs. Both systems fully functional!
**Dec 27 (AM v2):** Fixed RPC checksum mismatch - synced server's lobby.gd with client: (1) Added is_ammo parameter to c_try_buy_weapon, (2) Added c_try_upgrade_weapon RPC stub, (3) Added c_try_buy_perk RPC stub. Server now matches client RPC signatures (fixes "rpc node checksum failed" error).
**Dec 27 (AM):** Mode-specific element filtering - (1) PVP mode: Removes all zombie buyables (WeaponWallbuy/DoorBarrier) via recursive search after map load, (2) Zombie mode: Blocks PVP map pickups from spawning pre-match (match_started flag differentiates map pickups from zombie drops), (3) Zombie drops: Spawn after match starts but hide Platform/MeshHolder visuals (lobby.gd:14,232,362-379,208-227)
**Dec 26 (Late PM v9):** Implemented buyables core - BuyableBase class, refactored weapon_wallbuy.gd (ammo/weapon distinction), DoorBuyable (slide/swing/roll/debris), WeaponForge, PerkMachine (8 military perks: Tactical Vest/Fast Hands/etc), added RPC handlers. Ready for map setup + server implementation.
**Dec 26 (Late PM v8):** Created BUYABLES.md design doc - rebranded to military theme (Weapon Forge, Tactical Vest, etc)
**Dec 26 (Late PM v7):** Ammo crates now fill both weapons - replenish_ammo() loops through weapons_cache to refill reserve ammo + current magazine for all weapons in inventory (player_local.gd:385-394)
**Dec 26 (Late PM v6):** Redesigned zombie HUD/UI - converted from programmatic creation to zombie_hud.tscn. Clean/minimal styling matching ammo/health UI. Removed 80+ lines of Label.new() code from hud_manager.gd.
** Dec 26 (Late PM v5):** Fixed scoreboard issues in zombie mode + grenades damage zombies now
**Dec 26 (Late PM v4):** Spectator camera improvements: (1) Camera resets to default position on respawn (player_local.gd:529), (2) Increased spectator offset to 5u up + 5u back for better viewing angle (player_local.gd:563-564)
**Dec 26 (Late PM v3):** Fixed spectator camera positioning - now only moves camera, not entire player body. Prevents clipping/collision with spectated player.
**Dec 26 (Late PM v2):** Fixed spectator/respawn bugs: (1) Respawn now updates teammate cards to show alive status (lobby.gd:629), (2) Spectator mode re-enables physics processing for camera updates (player_local.gd:504), (3) Added freeze() exception for spectating (player_local.gd:139)
**Dec 26 (Late PM v1):** Implemented death/spectator/respawn improvements: (1) Dead players invisible - set_visible(false) when waiting for respawn (lobby.gd:606), (2) Spectator mode - dead players follow alive teammates' cameras, tab to cycle targets (player_local.gd:497-567), (3) Revive timing fix - players respawn at break timer START instead of wave start (wave_manager.gd:150), (4) Teammate health updates - already working via existing update_health broadcasts after revive/respawn
**Dec 26 (PM):** Implemented 4 zombie features + countdown UI: (1) Pistol-only start - forced weapon_id=0 in spawn, skips weapon selection in zombies mode, (2) Death/respawn system - is_waiting_for_respawn state, respawn at wave start, (3) Grenades damage zombies - explode() checks ZombieServer, (4) Auto-target - removed 5m threshold, (5) Countdown UI - 5s timer w/ map name replaces weapon selection in zombies mode (lobby.gd:253, zombies_countdown_ui.gd/.tscn)
**Dec 26 (AM):** Reviewed docs (too verbose, need consolidation)
**Dec 24:** Simplified zombie AI, added jump animations, smart target switching
**Dec 23:** Zombie mode MVP - waves, economy, wallbuys, 2-weapon inventory
