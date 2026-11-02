# DEBUG_DEV_UI_SYSTEM

Status: in progress
Owner: gameplay/tools
Runtime target: Godot 4 (`custodian/`)

## Purpose

Replace print/debug spam with a deterministic-safe, opt-in dev layer that keeps simulation clean and provides RTS-grade visibility into systems (waves, turrets, AI, economy).

## Non-Negotiable Constraints

- **Simulation stays deterministic.** No debug logic inside core simulation ticks.
- **No print spam** from gameplay systems. Debug data is written to a bus, not to console/render.
- **No debug draw inside systems.** All overlays rendered by a dedicated dev layer.
- **Opt-in and toggleable.** Debug UI and overlays can be fully disabled.
- **Godot-native UI only.** The former Dear ImGui dependency and the later third-party `dev-console` addon are both retired; use the F12 `Control`-based debug screen, the Observatory surfaces, and the native Developer Shell (`/root/DevConsole`).
- **Debug mutation is queued.** Debug panels may write to debug overrides or `DebugBus.queue_command(...)`; gameplay systems apply commands only at explicit safe boundaries.

## Architecture (One-Way Data Flow)

```
Simulation (deterministic)
    ↓
Debug Data Extraction (pure data, read-only)
    ↓
DebugBus (autoload singleton)
    ↓
DebugSnapshotCollector (post-tick/read-only snapshots)
    ↓
Godot Control DevUI
    ↓
DebugDraw (Node2D overlays)
```

## Nodes and Files

Current runtime assets:

- `custodian/debug/debug_bus.gd` (autoload singleton)
- `custodian/debug/debug_snapshot_collector.gd` (autoload singleton)
- `custodian/game/ui/hud/debug_screen.tscn` (F12 Godot-native diagnostics)

Planned/additional runtime assets:

- `custodian/debug/debug_controller.gd`
- `custodian/debug/debug_draw.gd`
- `custodian/debug/inspector_probe.gd`
- `custodian/debug/dev_ui.tscn` / `custodian/debug/dev_ui.gd` only if a Godot `Control`-based debug surface is needed later

Scene integration (runtime):

- `custodian/scenes/game.tscn` add nodes:
  - `DebugController` (Node)
  - `DevUI` (CanvasLayer)
  - `DebugDraw` (Node2D) under `World` (for correct world-space overlays)
  - `InspectorProbe` (Node2D) under `World`
  - `DebugCollector` (Node) for stats + overlay ingestion

## DebugBus (Singleton)

Central, pull-based data store. All debug info flows here.

Core fields:

- `enabled: bool`
- `overlay_mode: int` (0..5)
- `stats: Dictionary` (category → key → value)
- `events: Array[String]` (max 100)
- `overlays: Dictionary` (layer → array of primitive specs)
- `debug_overrides: Dictionary`
- `command_queue: Array[Dictionary]`
- `selected_entity: Node` (locked)
- `hovered_entity: Node` (current hover)
- `minimal_mode: bool` (stats-only)

API surface:

- `set_stat(category: String, key: String, value)`
- `push_event(category: String, msg: String)`
- `clear_frame_overlays()`
- `set_overlay(layer: String, items: Array)`
- `set_category(category: String, value)`
- `set_debug_override(key: String, value)`
- `queue_command(command: Dictionary)`
- `drain_commands()`

Rules:

- `push_event()` is a no-op when `enabled == false`.
- `events` is bounded (default 100). Oldest dropped first.
- Overlays are frame-scoped; cleared once per frame by controller.
- Debug commands are not applied by UI code. Runtime systems drain and apply them at safe boundaries.

## Native Developer Shell

`custodian/game/ui/debug/dev_console_service.gd` is the `/root/DevConsole` autoload and the command-registry/execution authority; `dev_console_panel.gd`/`.tscn` and `dev_console_style.gd` are its Godot-native presentation, built from `BlackReliquaryPalette`/`BlackReliquaryStyles`. It opens and closes with backtick/tilde, bottom-docked, and is gated end-to-end by `DevMode.allows(&"debug_ui")`.

It replaces two retired predecessors in turn: the original Dear ImGui Director Console, and the third-party `dev-console` Godot addon that followed it. Both are fully removed (plugin, autoload target, and config). F12 `debug_hud`, F9/F10 Developer Observatory, and this Developer Shell are the supported developer interfaces. `DebugBus` and `DebugSnapshotCollector` remain available as read-only data infrastructure for Godot-native consumers; the Developer Shell does not read `DebugBus` automatically (it is a command surface, not a log sink).

Command registration preserves the legacy addon's public contract exactly, since `ui.gd`'s `_register_devconsole_commands()` depends on it unchanged:

- `add_command(name, callback, metadata = {})` -- two-argument legacy calls remain valid.
- `add_signal(name, target_signal)`.
- Dispatch is always `callback.callv(parts)`, so every registered callback -- built-in or HUD-registered -- must be able to accept a variable number of positional arguments (the HUD adapter's `func(...args): return handler.call(args)` shape, or an equivalent variadic lambda).

Historical controls from the retired Director Console were:

- F3 toggled `/root/DebugBus.enabled`.
- Shift+F3 toggled minimal stats mode.
- World/ProcGen tab showed seed/profile, generation mode, terrain fallback/connectivity, required/missing cell counts, and rescue-carved cells.
- Sectors tab showed a table of sector intelligence snapshots.
- Events tab showed bounded debug/observatory timeline events.
- Combat, Actors, and Animation tabs were scaffolds for read-only tuning visibility and later adapter-specific details.

Data flow for that read-only data infrastructure remains one-way:

```
Gameplay systems
    -> read-only snapshot methods / groups
    -> DebugSnapshotCollector
    -> DebugBus
    -> F12 debug screen / Observatory
```

If a panel or console command needs a dev action such as spawning, seed regeneration, or profile swapping, it must queue a command on `DebugBus` instead of directly mutating core systems from UI code.

### Developer Shell Gameplay Input Isolation

A focused `LineEdit` alone does not stop `Input.is_action_pressed()` from also reporting movement/attack/etc. to gameplay, since the Operator samples raw input on the fixed simulation tick, not the render/GUI tick. The seam lives in `operator_input_router.gd`'s `sample_suppressed()`, called from `operator.gd::_sample_input_frame()` whenever `DevConsole.is_open()`:

- It returns `OperatorInputFrame.neutral()` -- no movement, no pressed actions -- for that tick.
- It still folds the real hardware state into the router's own `_previous_pressed` bookkeeping, so a key held across the whole time the shell is open does not manufacture a phantom `just_pressed` edge once the shell closes and ordinary sampling resumes.
- External control (replay, AI, possession) is a separate seam and is untouched by this check.

The developer shell and the in-world gameplay command terminal (`ui.gd`'s `_terminal_open` state) are independent modals that must not overlap: `DevConsoleService.open_console()` refuses to open while the gameplay terminal is up, and `ui.gd::open_command_terminal()` closes the developer shell before claiming input. F9 Observatory and F12 debug screen remain independent of both.

## Input Model

InputMap actions:

- `debug_toggle` → F3 (master toggle)
- `debug_overlay_cycle` → F4 (cycle overlay layers)
- `debug_lock_inspector` → F5 (lock hovered entity)
- `debug_minimal` → Shift + F3 (stats-only UI)

Behavior:

- F3 toggles `DebugBus.enabled`.
- Shift+F3 toggles `DebugBus.minimal_mode`.
- F4 cycles `overlay_mode` (0..5).
- F5 toggles inspector lock to hovered entity.

## Dev UI Layout (RTS Standard)

CanvasLayer panel layout:

- **Left panel**: system stats (grouped by category)
- **Right panel**: entity inspector (hover + lock)
- **Bottom panel**: event timeline

Stats categories (initial):

- `[SIM]` FPS, Tick Time (ms), Entities Active
- `[COMBAT]` Enemies Alive, Projectiles Active, Avg DPS
- `[AI]` Path Requests, Active Targets
- `[WAVE]` Wave #, Spawn Queue Size, Time To Next Wave
- `[ECONOMY]` Resources/sec, Storage (future)

Minimal mode hides inspector + timeline, keeps stats only.

### UI Update Rules

- UI only updates when `DebugBus.enabled`.
- Avoid heavy string work; build strings once per frame or on change.
- Label text assembled by category for readability.

## Entity Inspector

Behavior:

- Hover → preview entity under mouse.
- Click or F5 → lock to hovered entity.
- If locked, hover changes do not override.

Example output:

```
[Turret_12]
State: Firing
Target: Enemy_44
Range: 96
Cooldown: 0.12s
DPS: 18

[Enemy_44]
HP: 32 / 50
State: Advancing
Path Index: 6/14
Velocity: (1.2, 0.0)
```

Inspector data is read-only and compiled via the DebugBus in the extraction layer (no direct UI access to system internals).

## Event Timeline

- Max 50–100 events
- Timestamped + categorized
- Examples:
  - `[12.33] WAVE: Spawn started (Wave 3)`
  - `[12.40] AI: Enemy_44 acquired target`
  - `[12.52] COMBAT: Turret_12 fired`

## World Overlays

Overlay modes (cycle with F4):

0. OFF
1. RANGES (turret radius)
2. PATHS (enemy paths)
3. TARGETING (turret → target lines)
4. AI STATES (color-coded enemies)
5. ALL

Overlays are rendered in `DebugDraw` only, never inside gameplay systems.

Overlay payload example:

```
DebugBus.set_overlay("ranges", [
  {"pos": turret.global_position, "radius": 64, "color": Color(1, 0, 0, 0.6)}
])
```

## Data Extraction Layer (Pure Data)

Systems should push summary stats and overlay primitives without side effects.

Examples:

- `DebugBus.set_stat("COMBAT", "Projectiles", projectile_count)`
- `DebugBus.set_stat("WAVE", "Queue", spawn_queue.size())`
- `DebugBus.push_event("AI", "Enemy_%s retargeted" % enemy_id)`

All extraction runs **after** simulation tick completion to avoid influencing determinism.

## First Implementation Slice (Minimal Pass)

1. Autoload `DebugBus`.
2. Add `DevUI` panel with stats + event log only.
3. Replace 3–5 prints with `set_stat()`/`push_event()` in core systems.
4. Add F3 toggle.

This delivers immediate readability and performance wins.

## Second Implementation Slice (RTS-Grade)

1. Add inspector panel + hover/lock.
2. Add overlay cycling and `DebugDraw`.
3. Implement overlay layers for turrets, paths, and targeting.
4. Add categorized stats across systems.

## Performance and Safety

- Debug UI is disabled by default.
- String formatting is bounded and gated.
- Overlays cleared each frame with `DebugBus.clear_frame_overlays()`.
- No debug rendering or logging inside deterministic sim systems.

## Integration Notes

- `DebugController` owns the per-frame `clear_frame_overlays()` call.
- `InspectorProbe` resolves hovered entity via collision or spatial query, then writes to DebugBus.
- World overlays should be drawn in `DebugDraw` under `World` for correct transforms.

## Risks / Pitfalls

- Flooding stats or events makes UI unreadable.
- Updating heavy UI strings every frame can hurt performance.
- Any debug logic inside simulation breaks determinism and future replay.

## No New Animation Assets

This system is UI-only and does not require new sprite or animation assets.
