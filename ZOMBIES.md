# Zombie Mode Reference

## Features
- Wave-based spawning with difficulty scaling
- Points/economy system
- Zombie drops (health/ammo)
- 3 zombie types (Normal, Fast, Tank)
- 1-2 player co-op
- Weapon wallbuys, door barriers
- 2-weapon inventory

## Key Files

### Server (fps-udemy-server)
- `player/zombie/zombie_server.gd/tscn` - Zombie AI
- `server/zombies_mode/wave_manager.gd` - Wave spawning
- `player/buyables/weapon_wallbuy_server.gd/tscn`
- `player/buyables/door_barrier_server.gd/tscn`
- `server/lobby.gd` - Economy/match flow

### Client (fps-udemy-client)
- `player/zombie/zombie_remote.gd/tscn` - Zombie rendering
- `player/weapon_inventory.gd` - 2-weapon system
- `player/buyables/weapon_wallbuy.gd/tscn`
- `player/buyables/door_barrier.gd/tscn`
- `ui/hud/interaction_prompt.gd/tscn`
- `server/lobby.gd` - RPC handling

## Zombie Types
| Type   | HP  | Speed | Damage | Points |
|--------|-----|-------|--------|--------|
| Normal | 100 | 3.0   | 15     | 100    |
| Fast   | 60  | 5.5   | 10     | 150    |
| Tank   | 300 | 1.5   | 30     | 200    |

## Wave Scaling
- Base: 5 zombies + 3 per wave
- 10s break between waves
- Type distribution:
  - Waves 1-3: 100% normal
  - Waves 4-6: 80% normal, 20% fast
  - Waves 7+: 60% normal, 25% fast, 15% tank

## Economy Pricing
**Weapons:**
- SMG: 1000 / Ammo: 500
- Shotgun: 1500 / Ammo: 500
- AR: 2000 / Ammo: 750
- LMG: 2500 / Ammo: 750
- Sniper: 3000 / Ammo: 1000

**Doors:** 750-1250 (varies)

## Key RPCs

### Client → Server
- `c_try_buy_weapon(weapon_id)`
- `c_try_buy_door(door_id)`

### Server → Client
- `s_spawn_zombie(zombie_id, position, zombie_type)`
- `s_zombie_died(zombie_id)`
- `s_update_player_points(points)`
- `s_start_wave(wave_number)`
- `s_wave_complete(wave_number)`
- `s_update_zombies_remaining(count)`
- `s_update_break_time(seconds)`
- `s_weapon_purchased(weapon_id, is_ammo)`
- `s_door_opened(door_id)`
- `s_purchase_failed(reason)`

## Zombie AI States
- IDLE → CHASE → ATTACK → DEAD
- JUMPING (during jump point animations)
- Uses NavigationAgent3D, falls back to direct movement
- Targets nearest player, reevaluates every 2s

## Jump Points
- LINEAR: Walk animation (stairs/ramps)
- JUMP: Arc animation (containers/platforms)
- Trigger radius: 2.0m default
- Duration: 1-2s randomized
- 2s cooldown between jumps

## Known Issues
- No offline/solo mode
- Die = game over (no respawn system)
- No end-match logic (infinite waves)
- Grenades don't damage zombies
- Simple capsule mesh (no animations)
