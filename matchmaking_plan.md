# Matchmaking Overhaul Plan

**Status:** Finalized Design - Ready for Implementation
**Last Updated:** 2025-12-27

---

## Vision

**Simple, modular lobby system** with two primary user paths:
1. **CREATE LOBBY** - You're the host, full control
2. **QUICK PLAY** - Auto-match into any available lobby

All paths lead to the same **Waiting Room** where lobbies start.

---

## Current System (To Be Replaced)

**Client:**
- `main_menu.gd` - Basic mode/map selection
- Hardcoded auto-match into 2-player lobbies
- No lobby control

**Server:**
- `MAX_PLAYERS_PER_LOBBY = 2` (hardcoded)
- Auto-creates lobbies, locks when full
- No host controls, no variable sizes

---

## Core Requirements

✅ **Variable lobby sizes:** 1-4 for Zombies, 2-4 for PvP
✅ **Host controls:** Start game, kick players
✅ **Modular matchmaking:** Create, Quick Play, Join Code
✅ **Server-based solo:** 1-player lobbies run on server (no offline mode for now)
✅ **Scalable:** Easy to add browser, parties, invites later

---

## New Architecture

### 1. Core Lobby System (Server Foundation)

**Server (fps-udemy-server/server.gd):**
```gdscript
var lobbies: Dictionary = {}  # lobby_id -> Lobby instance

# Core RPCs:
@rpc c_create_lobby(player_name, max_players, map_id, game_mode, is_public) -> lobby_id
@rpc c_join_lobby(lobby_id, player_name) -> success/fail
@rpc c_quick_play(player_name, mode, map_pref, size_pref)
@rpc c_leave_lobby()
@rpc c_start_lobby()  # host only
@rpc c_kick_player(player_id)  # host only

@rpc s_lobby_state_updated(lobby_data)  # broadcast to lobby
@rpc s_joined_lobby(lobby_id, lobby_data)
@rpc s_kicked_from_lobby(reason)
```

**Lobby Metadata (server/lobby.gd):**
```gdscript
var lobby_id: String      # 6-char alphanumeric code
var host_id: int          # First player = host
var max_players: int      # 1-4
var current_players: Array[int]
var map_id: int
var game_mode: int        # PVP or ZOMBIES
var status: int           # WAITING, STARTING, IN_GAME
var is_public: bool       # Joinable via quick play?

# Validation:
- PvP: max_players must be 2 or 4 (even teams)
- Zombies: max_players = 1, 2, 3, or 4
- Solo (1 player): Auto-starts, skips waiting room
```

**Quick Play Matchmaking Logic:**
```gdscript
func handle_quick_play(client_id, mode, map_pref, size_pref):
    # Find public lobbies matching preferences:
    var matches = find_public_lobbies(mode, map_pref, size_pref)

    if matches.size() > 0:
        join_lobby(matches[0].lobby_id, client_id)
    else:
        # No match found, create new public lobby
        var default_size = 4 if mode == ZOMBIES else 4
        create_lobby(client_id, default_size, map_pref, mode, is_public=true)
```

---

### 2. Client UI (fps-udemy-client)

#### **Main Menu (Updated main_menu.gd)**

**New Layout:**
```
┌─────────────────────────────────┐
│                                 │
│     [ CREATE LOBBY ]            │  ← Full control
│                                 │
│     [ QUICK PLAY ]              │  ← Auto-match
│                                 │
│  ─────────── or ────────────    │
│                                 │
│  Join Code: [______] [Join]     │  ← Direct join
│                                 │
└─────────────────────────────────┘
```

---

#### **A. Create Lobby Screen**
**File:** `ui/lobby/create_lobby_ui.tscn/.gd`

**Layout:**
```
┌─────────────────────────────────┐
│  Create Lobby                   │
│                                 │
│  Mode: ⚪PvP  ⚪Zombies          │
│  Map: [Farm ▼]                  │
│  Max Players:                   │
│    ⚪2  ⚪3  ⚪4                  │
│    (⚪1 only for Zombies)       │
│                                 │
│  Public: ☑ (others can join)    │
│                                 │
│  [ Create ]  [ Cancel ]         │
└─────────────────────────────────┘
```

**Behavior:**
- Mode toggle changes available player counts
  - PvP: Only 2, 4 available
  - Zombies: 1, 2, 3, 4 available
- Click Create → `Server.c_create_lobby()` RPC
- Server creates lobby, returns lobby_id
- Transition to Waiting Room (you're host)

---

#### **B. Quick Play Screen**
**File:** `ui/lobby/quick_play_ui.tscn/.gd`

**Layout:**
```
┌─────────────────────────────────┐
│  Quick Play                     │
│                                 │
│  Mode: ⚪PvP  ⚪Zombies          │
│  Map: [Any Map ▼]               │
│  Players: [Any ▼]               │
│    (or specific: 2, 3, 4)       │
│                                 │
│  [ Play ]  [ Cancel ]           │
└─────────────────────────────────┘
```

**Behavior:**
- Sends `Server.c_quick_play()` with preferences
- Server finds best match or creates new lobby
- Shows "Searching..." overlay
- Transitions to Waiting Room when matched

---

#### **C. Waiting Room**
**File:** `ui/lobby/waiting_room_ui.tscn/.gd`

**Layout (Host View):**
```
┌─────────────────────────────────┐
│  Farm - Zombies (2/4 Players)   │
│  Lobby Code: ABC123             │
│                                 │
│  ✓ PlayerName (You) [HOST]      │
│  ✓ OtherPlayer        [Kick]    │
│  ⏳ Waiting for players...       │
│                                 │
│  [Start Game] [Leave Lobby]     │
└─────────────────────────────────┘
```

**Layout (Non-Host View):**
```
┌─────────────────────────────────┐
│  Farm - Zombies (2/4 Players)   │
│  Lobby Code: ABC123             │
│                                 │
│  ✓ HostName [HOST]              │
│  ✓ PlayerName (You)             │
│  ⏳ Waiting for host...          │
│                                 │
│  [Leave Lobby]                  │
└─────────────────────────────────┘
```

**Host Controls:**
- **Start Game** button (enabled when valid player count met)
  - Zombies: ≥1 player
  - PvP: ≥2 players AND even count
- **Kick** button next to each non-host player
- Can see and share lobby code

**Non-Host:**
- View player list
- Leave lobby
- See lobby code

**Special Case - Solo (1 Player Zombies):**
- Skip waiting room entirely
- Create lobby → auto-start immediately

---

### 3. Matchmaking Modules (Pluggable Design)

All three entry points use the same core lobby system:

**1. Create Lobby:**
```gdscript
func create_lobby(settings):
    var lobby_id = Server.c_create_lobby(...)
    show_waiting_room(lobby_id, is_host=true)
```

**2. Quick Play:**
```gdscript
func quick_play(preferences):
    Server.c_quick_play(...)
    # Server finds match or creates lobby
    # → show_waiting_room(lobby_id, is_host=?)
```

**3. Join Code:**
```gdscript
func join_by_code(code):
    Server.c_join_lobby(code)
    # → show_waiting_room(code, is_host=false)
```

**Future Extensions (Easy to Add):**
- Lobby browser (list public lobbies)
- Party system (group before queueing)
- Friend invites (send lobby code via Steam/etc)

---

## Implementation Phases

### Phase 1: Server Foundation
**Files:** `fps-udemy-server/server.gd`, `fps-udemy-server/server/lobby.gd`

1. Remove `MAX_PLAYERS_PER_LOBBY` constant
2. Add `max_players`, `host_id`, `lobby_id`, `is_public` to Lobby class
3. Implement lobby code generation (6-char alphanumeric)
4. Add new RPCs:
   - `c_create_lobby()`
   - `c_join_lobby()`
   - `c_quick_play()`
   - `c_start_lobby()` (with host validation)
   - `c_kick_player()` (with host validation)
5. Implement quick play matchmaking logic
6. Add host migration (promote oldest player if host leaves)

**Test:** Create lobby via console, join via code

---

### Phase 2: Client UI - Waiting Room
**Files:** `ui/lobby/waiting_room_ui.tscn/.gd`

1. Create waiting room scene
2. Player list display
3. Host controls (Start/Kick buttons)
4. Lobby code display
5. Leave lobby functionality
6. Wire up RPCs to server

**Test:** Two clients can join same lobby, host can start

---

### Phase 3: Client UI - Create & Quick Play
**Files:** `ui/lobby/create_lobby_ui.tscn/.gd`, `ui/lobby/quick_play_ui.tscn/.gd`

1. Create lobby creation screen
2. Create quick play screen
3. Update main menu with new buttons
4. Wire up both flows to waiting room

**Test:** Can create lobby, can quick play into existing lobby

---

### Phase 4: Join Code & Polish
**Files:** `main_menu.gd`, `ui/lobby/*.gd`

1. Add join code input to main menu
2. Implement solo auto-start (skip waiting room)
3. Error handling (lobby full, invalid code, etc.)
4. Lobby state synchronization (player join/leave updates)
5. Host migration handling

**Test:** All edge cases, disconnects, etc.

---

## Technical Decisions

### Decided:
✅ **Server-based solo:** 1-player lobbies run on server (simpler, no code duplication)
✅ **Two main paths:** Create (control) vs Quick Play (convenience)
✅ **Modular design:** Easy to add browser/parties later
✅ **Host migration:** Promote oldest player if host leaves
✅ **Lobby codes:** 6-character alphanumeric for easy sharing

### To Decide:
✅ **Auto-start when full?** Host always needs to click "Start Game" (no auto-start)
✅ **Lobby timeout:** Delete immediately when last player leaves
✅ **Quick play priority:** Always try to fill existing lobbies first (backfill priority)
✅ **Kicked player:** Show "You were removed from the lobby" message

---

## File Structure

```
fps-udemy-client/
├── ui/
│   ├── lobby/
│   │   ├── create_lobby_ui.tscn       [NEW]
│   │   ├── create_lobby_ui.gd         [NEW]
│   │   ├── quick_play_ui.tscn         [NEW]
│   │   ├── quick_play_ui.gd           [NEW]
│   │   ├── waiting_room_ui.tscn       [NEW]
│   │   └── waiting_room_ui.gd         [NEW]
│   └── main_menu/
│       └── main_menu.gd                [MODIFIED]
├── server/
│   └── server.gd                       [MODIFIED]

fps-udemy-server/
├── server/
│   ├── server.gd                       [MODIFIED]
│   └── lobby.gd                        [MODIFIED]
```

---

## Success Criteria

✅ Players can create lobbies with 1-4 player sizes
✅ Quick play auto-matches or creates new lobby
✅ Lobby codes work for direct joining
✅ Host can start game and kick players
✅ Solo zombies (1 player) works seamlessly
✅ PvP enforces even team sizes (2 or 4)
✅ Host migration works if host leaves
✅ Lobby state stays in sync across all clients

---

## Next Steps

1. **Review & approve this plan** ✓
2. **Start Phase 1:** Server foundation (lobby system, RPCs)
3. **Prototype waiting room UI** to validate UX
4. **Continue through phases** until complete
5. **Extensive testing** with edge cases
