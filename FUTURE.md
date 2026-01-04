# Future Features

Unimplemented ideas and design docs for later.

---

## Spectator System Overhaul

**Status:** Design complete, not started

### Vision
Unified spectator system for clients + server admin.

**Client Spectators:**
- Dead players spectate teammates (already works)
- Browse/watch other lobbies while waiting
- Multi-lobby spectating support

**Server Admin Panel:**
- UI to switch between lobbies 1-4
- Follow specific players (third-person camera)
- Admin controls: kick/end match/broadcast chat
- Auto-refresh lobby list

### Implementation Phases
1. Refactor client spectator (extract to `spectator_manager.gd`)
2. Build server UI (`spectator_ui.tscn`)
3. Add multi-lobby spectating RPCs
4. Admin panel features (kick/chat/end match)
5. Edge case handling
