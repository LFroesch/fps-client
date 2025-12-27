# Buyables System - Weapons & Doors

## Overview
This system allows players to purchase weapons and open doors using points earned in zombies mode.

## Components Created

### 1. Weapon Wallbuy (`weapon_wallbuy.tscn`)
- **Location**: `res://player/buyables/weapon_wallbuy.tscn`
- **Script**: `weapon_wallbuy.gd`
- **Purpose**: Allows players to buy weapons or ammo

#### Properties:
- `weapon_id` (int): Weapon type (0=pistol, 1=smg, 2=shotgun, 3=assault_rifle, 4=sniper, 5=lmg)
- `weapon_cost` (int): Cost to buy weapon (default: 1000)
- `ammo_cost` (int): Cost to refill ammo (default: 500)

#### Visual:
- Blue placeholder cube at position (0, 1.5, 0)
- Interaction area: 2x2x2 box around the weapon

#### Usage in Map:
1. Add `WeaponWallbuy` node to your map
2. Set `weapon_id` to desired weapon
3. Adjust costs if needed
4. Set unique position for each wallbuy

### 2. Door Barrier (`door_barrier.tscn`)
- **Location**: `res://player/buyables/door_barrier.tscn`
- **Script**: `door_barrier.gd`
- **Purpose**: Blocks areas until purchased

#### Properties:
- `door_id` (String): Unique identifier for this door
- `cost` (int): Points required to open (default: 750)

#### Visual:
- Semi-transparent red barrier (3m x 2.5m x 0.3m)
- Blocks player movement
- Fades and moves up when opened

#### Usage in Map:
1. Add `DoorBarrier` node to block a path
2. Set unique `door_id` (e.g., "door_1", "door_spawn_to_building")
3. Position to block desired area
4. Adjust cost based on map flow

### 3. Interaction Prompt (`interaction_prompt.tscn`)
- **Location**: `res://ui/hud/interaction_prompt.tscn`
- **Already added to HUD**: Yes
- **Purpose**: Shows "Press F" messages to player

## Setting Up in Your Map

### Example: Adding a Weapon Wallbuy
```
Map/
├── Weapons/
│   ├── SMG_Wallbuy (WeaponWallbuy)
│   │   └─ weapon_id = 1, weapon_cost = 1000
│   ├── Shotgun_Wallbuy (WeaponWallbuy)
│   │   └─ weapon_id = 2, weapon_cost = 1500
│   └── Sniper_Wallbuy (WeaponWallbuy)
│       └─ weapon_id = 4, weapon_cost = 3000
```

### Example: Adding Door Barriers
```
Map/
├── Doors/
│   ├── door_1 (DoorBarrier)
│   │   └─ door_id = "door_1", cost = 750
│   ├── door_2 (DoorBarrier)
│   │   └─ door_id = "door_2", cost = 1000
│   └── door_power (DoorBarrier)
│       └─ door_id = "door_power", cost = 1250
```

## Server-Side Integration

### Client → Server RPCs (Already Implemented)
- `c_try_buy_weapon(weapon_id: int)` - Request weapon purchase
- `c_try_buy_door(door_id: String)` - Request door opening

### Server → Client RPCs (Already Implemented)
- `s_weapon_purchased(weapon_id: int, is_ammo: bool)` - Confirm purchase
- `s_door_opened(door_id: String)` - Broadcast door opening
- `s_purchase_failed(reason: String)` - Notify failure
- `s_update_player_points(points: int)` - Update points display

### Server Implementation Needed
You need to add this to your **SERVER project** (`fps-udemy-server`):

```gdscript
# In server/lobby.gd or server/zombies_mode/economy_manager.gd

# Pricing tables
var weapon_costs = {
    0: 0,       # Pistol (free)
    1: 1000,    # SMG
    2: 1500,    # Shotgun
    3: 2000,    # Assault Rifle
    4: 3000,    # Sniper
    5: 2500     # LMG
}

var ammo_costs = {
    1: 500,     # SMG
    2: 500,     # Shotgun
    3: 750,     # Assault Rifle
    4: 1000,    # Sniper
    5: 750      # LMG
}

var door_costs = {
    "door_1": 750,
    "door_2": 1000,
    "door_power": 1250
}

var opened_doors = {}  # Track which doors are open

# Handle weapon purchase request
@rpc("any_peer", "call_remote", "reliable")
func c_try_buy_weapon(weapon_id: int) -> void:
    var peer_id = multiplayer.get_remote_sender_id()

    if not client_data.has(peer_id):
        return

    var player_points = client_data[peer_id].points
    var has_weapon = _player_has_weapon(peer_id, weapon_id)

    var cost = ammo_costs.get(weapon_id, 500) if has_weapon else weapon_costs.get(weapon_id, 1000)

    if player_points >= cost:
        # Deduct points
        client_data[peer_id].points -= cost

        # Send confirmation
        rpc_id(peer_id, "s_weapon_purchased", weapon_id, has_weapon)
        rpc_id(peer_id, "s_update_player_points", client_data[peer_id].points)
    else:
        rpc_id(peer_id, "s_purchase_failed", "Not enough points!")

# Handle door purchase request
@rpc("any_peer", "call_remote", "reliable")
func c_try_buy_door(door_id: String) -> void:
    var peer_id = multiplayer.get_remote_sender_id()

    if opened_doors.has(door_id):
        return  # Already open

    if not client_data.has(peer_id):
        return

    var player_points = client_data[peer_id].points
    var cost = door_costs.get(door_id, 750)

    if player_points >= cost:
        # Deduct points
        client_data[peer_id].points -= cost
        opened_doors[door_id] = true

        # Broadcast to all clients
        rpc("s_door_opened", door_id)
        rpc_id(peer_id, "s_update_player_points", client_data[peer_id].points)
    else:
        rpc_id(peer_id, "s_purchase_failed", "Not enough points!")

func _player_has_weapon(peer_id: int, weapon_id: int) -> bool:
    # Check if player already owns this weapon
    # Implementation depends on your weapon system
    return false
```

## Navigation Setup for Zombies

### Auto-Baking NavigationMesh

To allow zombies to navigate around doors and obstacles:

#### Method 1: Script-Based Auto-Bake
Add to your map root node:

```gdscript
extends Node3D

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D

func _ready():
    if nav_region and not nav_region.navigation_mesh:
        auto_bake_navigation()

func auto_bake_navigation():
    var nav_mesh = NavigationMesh.new()

    # Agent size (matches zombie capsule)
    nav_mesh.agent_height = 1.8
    nav_mesh.agent_radius = 0.4
    nav_mesh.agent_max_climb = 0.5
    nav_mesh.agent_max_slope = 45.0

    # Include collision shapes automatically
    nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_MESHES_AND_STATIC_COLLIDERS
    nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_BOTH

    # Precision
    nav_mesh.cell_size = 0.25
    nav_mesh.cell_height = 0.2

    # Bake and assign
    nav_region.navigation_mesh = nav_mesh
    nav_region.bake_navigation_mesh()

    print("Navigation mesh baked for ", name)
```

#### Method 2: Editor-Based Bake
1. Add `NavigationRegion3D` node to map
2. In Inspector → NavigationMesh:
   - Set **Source Geometry Mode**: `Mesh Instances + Static Colliders`
   - Set **Agent Height**: 1.8
   - Set **Agent Radius**: 0.4
   - Set **Cell Size**: 0.25
3. Click **"Bake NavigationMesh"** button
4. Save scene

### Important Notes
- NavigationMesh automatically includes `StaticBody3D` collision shapes
- Door barriers are `StaticBody3D`, so they block navigation
- When door opens, collision is disabled → zombies can path through
- Bake navmesh in CLIENT maps, then copy to SERVER maps

## Testing Checklist

- [ ] Weapon wallbuy shows prompt when approaching
- [ ] Prompt disappears when leaving area
- [ ] Pressing F sends purchase request
- [ ] Server deducts points correctly
- [ ] Client receives weapon/ammo
- [ ] Door shows prompt when approaching
- [ ] Door opens with fade animation
- [ ] Door collision disables after opening
- [ ] Multiple players can buy from same wallbuy
- [ ] Door stays open for all players after one purchase

## Weapon IDs Reference
```
0 = Pistol
1 = SMG
2 = Shotgun
3 = Assault Rifle
4 = Sniper
5 = LMG
```

## Next Steps

1. **Implement server-side logic** in your server project
2. **Add wallbuys to maps** (e.g., map_killroom.tscn)
3. **Set up NavigationRegion3D** in each zombie map
4. **Test in multiplayer** with points system
5. **Replace placeholder meshes** with proper 3D models
6. **Add sound effects** for purchases

## Notes
- Placeholder visuals (blue cube for weapons, red barrier for doors)
- "interact" input action (F key) already exists in project
- InteractionPrompt UI already added to HUD
- All client-side code complete and ready to test
- Server-side implementation required for functionality
