# World-State Simulation

This prototype models pressure on a static command post. The terminal layer is command-driven and backend-authoritative.

## Layout

- Entry point: `game/simulations/world_state/sandbox_world.py`
- Core logic: `game/simulations/world_state/core/`
- Terminal stack: `game/simulations/world_state/terminal/`
- Flask command endpoints:
  - `custodian-terminal/streaming-server.py` (UI server path)
  - `game/simulations/world_state/server.py` (world-state server module)

## Core State Model

- `GameState`
  - `time`: current tick.
  - `ambient_threat`: global pressure scalar.
  - `assault_timer`: hidden countdown to major assault.
  - `in_major_assault`: whether major assault is active.
  - `player_location`: current sector name.
  - `in_command_center`: derived location flag.
  - `faction_profile`: ideology + form + technology expression.
  - `is_failed`: terminal failure latch after COMMAND breach.
  - `failure_reason`: locked operator-facing failure reason.
  - `sectors`: dictionary of `SectorState` by name.
  - `focused_sector`: optional focus sector ID (cleared after assault).
  - `hardened`: posture flag that compresses assault damage (cleared after assault).
  - `archive_losses`: persistent counter of ARCHIVE damage transitions.
- `SectorState`
  - `damage`: persistent wear.
  - `alertness`: volatility that rises with pressure and decays slowly.
  - `power`: local power availability.
  - `occupied`: whether hostiles are present this tick.
  - `effects`: lingering sector conditions.
  - `global_effects`: campaign-level conditions.

## Sectors (Phase 1 Layout)

- COMMAND
- COMMS
- DEFENSE GRID
- POWER
- ARCHIVE
- STORAGE
- HANGAR
- GATEWAY

## Simulation Flow (Terminal Mode)

1. Accept one operator command.
2. Parse and normalize command intent.
3. Execute command action.
4. Advance world by wait-unit steps only when command semantics require time (`WAIT`, `WAIT NX`).
5. Return `CommandResult` payload (`ok`, `text`, optional `lines`, optional `warnings`).

## Command-Driven Stepping

- No hidden background stepping while input is idle.
- Each accepted time-bearing command advances one or more simulation steps.
- Read-only commands return state without advancing time.
- Major assault timers and ambient events resolve during step execution.

This keeps pacing deterministic and aligned with explicit operator intent.

## Terminal Command Set (Current)

- `STATUS`: high-level board view of time, threat bucket, assault phase, and sector summary.
- `WAIT`: advance one wait unit (5 ticks) with 0.5-second pacing between internal ticks.
- `WAIT NX`: advance `N` wait units (`N x 5` ticks) and emit observed event/signal lines in order.
- `FOCUS <SECTOR_ID>`: reallocate attention to a sector ID (for example `FOCUS POWER`) without advancing time.
- `HARDEN`: reduce the number of sectors hit in the next assault and concentrate damage into higher-risk sectors.
- `HELP`: list available commands.
- `RESET` / `REBOOT`: reset in-process state (required during failure lockout).

## Command Parser

The parser trims raw input, tokenizes using shell-style quotes, and normalizes the command verb to uppercase.

## Events (Procedural)

Ambient events come from a catalog derived from hostile profile dimensions:

- ideology (why they attack)
- form (what they are)
- technology expression (how they fight)

Each event defines `min_threat`, `cooldown`, `sector_filter`, and `weight`, with optional consequence chains and persistent effects.

## Failure Conditions

Terminal failure latches when COMMAND damage reaches `COMMAND_CENTER_BREACH_DAMAGE`.
Terminal failure also latches when ARCHIVE loss count reaches `ARCHIVE_LOSS_LIMIT`.

- Once failed, normal command progression is locked.
- Only `RESET` / `REBOOT` are accepted for recovery.

## Assault Behavior

Major assaults are countdown-driven and influenced by vulnerable sector damage.

- Assaults increase ambient threat.
- Assaults apply additional damage and alertness to targeted sectors.
- Assaults end after a short randomized duration.

## Tuning Notes

- Primary tuning lives in `game/simulations/world_state/core/config.py`.
- Event pacing can be shifted by event `cooldown` and `weight` values.
- Keep output terse and operational.

## Run It

From this directory:

```bash
python sandbox_world.py
```

### Phase 1 Terminal

```bash
WORLD_STATE_MODE=repl python sandbox_world.py
```

Use `WORLD_STATE_MODE=sim` to run the autonomous loop.
