# The Last Routekeeper — Event Design Spec

**Status:** draft  
**Owner:** agent  
**Runtime:** Godot 4.x / Sundered Keep  
**Event ID:** `last_routekeeper`  
**Type:** one-time residual-system event  
**Tone:** grief, duty, failed preservation, route memory  

---

## 0. Feature Summary

A rare, authored random event inside Sundered Keep. The player recovers the field-survey trace of **B. Chaffee**, an auxiliary routekeeper/survey custodian who was assigned to mark a safe return path through the ruined causeway.

The player does **not** meet "you" as a talking NPC. They find an old route survey trace: a half-failed residual projection still marking a safe path under or across the causeway.

This fits CUSTODIAN's core fantasy: the player wins by preserving and reconstructing knowledge, not by killing everything.

---

## 1. Design Goals

### Primary

1. Add a rare, authored random event to Sundered Keep.
2. Make the event feel like a **recovered institutional trace**, not a living quest giver.
3. Reward the player with **map/traversal clarity**, not stats.
4. Reuse existing Sundered Keep interaction/HUD/minimap patterns.
5. Track the event as one-time per run/save.
6. Register missing production assets in `REQUIRED_ASSETS.md`.

### Non-Goals

B. Chaffee is **not** any of these:

- companion
- merchant
- combat ally
- quest hub NPC
- repeating gag NPC
- lore-dump narrator
- power-granting upgrade source

He should feel like a dead maintenance function that almost finished its job.

---

## 2. Runtime Anchors

The event attaches to the existing Sundered Keep runtime.

### Key Files

| File | Role |
|---|---|
| `game/world/sundered_keep/sundered_keep_map.gd` | Event spawn, interaction routing, hint reveal |
| `game/world/sundered_keep/sundered_keep_interactable.gd` | Reused interactable bridge |
| `game/world/events/last_routekeeper/last_routekeeper_event.gd` | Event controller (placeholder visuals, recovery logic) |
| `game/world/events/last_routekeeper/last_routekeeper_event_state.gd` | Event state resource (notes, lines, status) |
| `game/systems/core/state/world_event_memory.gd` | Autoload for one-time event tracking |
| `content/levels/sundered_keep/sundered_keep_front_gate_large.json` | Optional level-data-driven tile markers |
| `REQUIRED_ASSETS.md` | Missing production art registry |

### Precedent

The event follows the authored-event pattern established by Ash-Bell:

```
game/world/events/ash_bell/
  forlorn_ritualant_site.gd
  forlorn_ritualant_npc.gd
  ash_bell_event_state.gd
  ash_bell_interactable.gd
  ash_bell_trigger.gd
  forlorn_ritualant_site.tscn
```

The Routekeeper event adds a lighter-weight slice version: state resource + controller + world memory, without a dedicated scene file.

---

## 3. Eligibility & Trigger

### Conditions

Event may spawn when all of the following are true:

- Active map is Sundered Keep.
- Player has entered Return Causeway / front gate area.
- Main Gate is open **OR** `force_routekeeper_event == true`.
- Event memory does not mark `last_routekeeper` complete or spawned.
- Candidate tile is valid.

### Deterministic Roll

Base chance: `4%`  
After Main Gate opened: `12%`  
Debug override: `force_routekeeper_event` exported bool

Roll uses `WorldEventMemory.get_event_seed()` with a salt composing `level_id`, trace tile, and gate state — not raw `randf()`.

### Recommended Tiles

```
routekeeper_trace_tile   = Vector2i(37, 53)  # near lower causeway/shore
routekeeper_hint_tile    = Vector2i(25, 39)  # lower stair / underpass connection
```

In V1, these are `@export` vars on `SunderedKeepMap`. For cleaner level-authoring, they can be driven by JSON markers later.

---

## 4. Event Sequence

```
1. Route authority trace appears near lower causeway/underpass.
2. Player sees: survey beacon, chalk/copper marks, faint residual projection.
3. Player interacts with the trace.
4. HUD shows "ROUTEKEEPER TRACE".
5. Route header + 3-4 route notes print/log/display.
6. Local traversal hint marker is revealed.
7. Routekeeper trace note is granted (inventory + archive).
8. Event marks complete permanently.
9. Projection fades. Interactable removed.
```

---

## 5. Player-Facing Text

### Authority Header

```
ROUTE AUTHORITY TRACE DETECTED
SIGNATURE: B. CHAFFEE
ASSIGNMENT: RETURN CORRIDOR SURVEY
STATUS: UNACKNOWLEDGED
```

### Route Notes

```
ROUTE NOTE 003:
BRIDGE VISIBLE. SHORE TRAVERSABLE. CENTER SPAN UNRELIABLE.

ROUTE NOTE 009:
MARKED THE LOWER STONES AGAIN. THE SEA KEEPS TAKING THE PAINT.

ROUTE NOTE 014:
IF THE GATE DOES NOT OPEN, THE ROAD BENEATH STILL REMEMBERS TRAFFIC.

ROUTE NOTE 018:
RETURNED TO MARK THE WAY BACK.
RETURN NOT OBSERVED.
```

### Recovery Message

```
ROUTEKEEPER TRACE RECOVERED
LOCAL TRAVERSAL HINT RECONSTRUCTED
```

---

## 6. Runtime Architecture

### New Files

```
game/systems/core/state/world_event_memory.gd
  — Autoload singleton
  — Tracks completed/spawned events per run
  — Stores event payloads
  — Provides deterministic seeded hashing

game/world/events/last_routekeeper/
  last_routekeeper_event_state.gd
    — Resource: LastRoutekeeperEventState
    — Exports signature, assignment, status, discovered/completed flags
    — Holds route_notes array
    — Provides get_header_lines() and get_recovery_lines()

  last_routekeeper_event.gd
    — Controller: LastRoutekeeperEvent (Node2D)
    — Builds placeholder visuals (Polygon2D-based residuals)
    — Attaches SunderedKeepInteractable child
    — Signal: trace_recovered(hint_tile: Vector2i)
    — Recovery animation (tween fade-out)
```

### Patches

```
game/world/sundered_keep/sundered_keep_map.gd
  — Preload event + constants
  — Export routekeeper_trace_tile, routekeeper_hint_tile, spawn chances, force bool
  — State vars for event instance, interaction reference, recovered flag, hint marker
  — _maybe_spawn_last_routekeeper_trace() called after gate opens
  — _handle_sundered_interaction match case: &"last_routekeeper_trace"
  — _update_hud_prompt() case for ROUTEKEEPER TRACE
  — Event methods: spawn, recover, hint reveal, note grant
  - _passes_last_routekeeper_roll deterministic check
  - WorldEventMemory bridge methods
```

### Autoload

```
project.godot
  — [autoload]
  — WorldEventMemory="*res://game/systems/core/state/world_event_memory.gd"
```

---

## 7. Optional Level JSON Integration

For V2, add markers to `sundered_keep_front_gate_large.json`:

```json
{ "id": "last_routekeeper_trace", "tile": [37, 53] }
{ "id": "last_routekeeper_hint", "tile": [25, 39] }
```

Then patch `_apply_marker()` to set the exported tile vars.

---

## 8. Required Production Assets

### Residual Projection Sprites

| Asset | Path | Purpose |
|---|---|---|
| idle animation | `custodian/assets/sprites/events/last_routekeeper/last_routekeeper_residual_idle_south_96x96_6f.png` | Faint standing/kneeling residual projection |
| mark animation | `custodian/assets/sprites/events/last_routekeeper/last_routekeeper_residual_mark_south_96x96_6f.png` | Route-marking motion |
| fade animation | `custodian/assets/sprites/events/last_routekeeper/last_routekeeper_residual_fade_south_96x96_8f.png` | Trace collapse after recovery |

### Prop / Decal Sprites

| Asset | Size | Purpose |
|---|---|---|
| `routekeeper_survey_beacon_01.png` | 32×64 | Broken route beacon |
| `routekeeper_chalk_marks_01.png` | 32×32 | Ground-level route mark decal |
| `routekeeper_route_hint_marker_01.png` | 32×32 | Revealed traversal marker |
| `routekeeper_hologram_pulse_01.png` | 64×64 (8f) | Faint pulse around beacon after recovery |

Each prop needs a `.game32.json` sidecar.

---

## 9. Validation

### Godot Check

```
godot --headless --check-only --quit
```

### Manual Checklist

1. Start Sundered Keep — event does not spawn before Main Gate (unless forced).
2. Open Main Gate — deterministic roll may spawn event.
3. Set `force_routekeeper_event = true` — trace appears at `routekeeper_trace_tile`.
4. HUD prompt shows "ROUTEKEEPER TRACE".
5. Interact — route notes print/log.
6. Hint marker appears at `routekeeper_hint_tile`.
7. Interactable disappears after recovery.
8. Leaving/returning does not respawn event.
9. Debug state includes spawned/recovered flags.
10. No hard errors if production art is absent.

---

## 10. Documentation Drift Risk

After implementing, update:

- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`
- `REQUIRED_ASSETS.md`
- `design/02_features/LAST_ROUTEKEEPER_EVENT_CODE.md`

Check whether Drive/project-context copies of `AGENTS.md` need refreshing if they are supposed to mirror the repo root.

---

## 11. Next Agent Slice

**Goal:** Implement The Last Routekeeper event in Sundered Keep.

**Files to create:**
- `game/systems/core/state/world_event_memory.gd`
- `game/world/events/last_routekeeper/last_routekeeper_event_state.gd`
- `game/world/events/last_routekeeper/last_routekeeper_event.gd`

**Files to patch:**
- `game/world/sundered_keep/sundered_keep_map.gd`
- `project.godot`

**Docs to create/update:**
- `design/02_features/LAST_ROUTEKEEPER_EVENT_CODE.md`
- `custodian/docs/ai_context/task_packets/LAST_ROUTEKEEPER_EVENT.md`
- `REQUIRED_ASSETS.md`
- `custodian/docs/ai_context/CURRENT_STATE.md`
- `custodian/docs/ai_context/FILE_INDEX.md`

**Constraints:**
- Non-combat, non-repeatable, non-social.
- Use deterministic seeded RNG via `WorldEventMemory`.
- Placeholder visuals when production art absent.
- Must not break existing Sundered Keep runtime.
