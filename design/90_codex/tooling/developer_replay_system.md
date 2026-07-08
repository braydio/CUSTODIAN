# Developer Replay System

Status: candidate
Category: tooling
Priority: P1
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A scrubbable playtest timeline that records key runtime state so the developer can replay what happened, inspect heatmaps, and diagnose bugs or design problems.

## Problem it solves

Playtest issues are hard to understand from memory. The player says, “I got killed unfairly,” but the real cause could be:

- enemy saw through wall
- sound propagated too far
- weapon animation timing was unclear
- dodge invulnerability started late
- room had no cover
- player missed a route
- AI state machine got stuck
- world-state dependency failed
- performance spike caused input lag

A Developer Replay System preserves enough data to inspect what actually happened.

## Why it fits CUSTODIAN

CUSTODIAN is becoming a systems-heavy game: AI, combat, repair, world state, procedural layout, heatmaps, simulation tiers, and animation timing. A replay system makes that complexity manageable.

Thematically, it also mirrors World Autopsy: the developer reconstructs a run from evidence.

## Player-facing effect

Indirect. Better tuning, fewer bugs, clearer combat, stronger levels.

Potential future player-facing version:

- death replay
- terminal reconstruction
- ghost path
- “Operator trace recovered”

## Systems touched

- Developer Observatory
- Telemetry
- Combat
- AI
- World State Graph
- Persistent World History
- Heatmaps
- Input
- Performance
- Save/load
- Debug UI

## Dependencies

Minimal version requires:

- event logging
- periodic snapshots
- stable entity IDs
- timestamped events

Full version benefits from:

- Developer Observatory
- Sector Heatmap
- World Event Timeline
- Faction Knowledge System
- Interest Management

## Risks

Recording too much data can hurt performance and create huge files.

Do not attempt video replay first. Record data, not frames.

Start with a ring buffer and export only when requested.

## Minimal version

Record a rolling buffer of:

- timestamp
- player position
- player velocity
- player health
- player facing
- current weapon
- dodge/parry/fire/heal events
- damage events
- enemy positions every 0.25 seconds
- enemy state changes
- world-state changes
- FPS samples

On death or manual hotkey, export JSON.

## Full version

Full version includes:

- scrubbable timeline UI
- map overlay playback
- heatmap playback
- AI state labels over time
- sound propagation events
- vision cone events
- world-state graph changes
- input timeline
- animation state timeline
- performance spikes
- deterministic replay for selected scenarios
- comparison between multiple test runs

## Replay philosophy

Do not record everything.

Record enough to answer:

- Where was the player?
- What did the player do?
- What was trying to kill them?
- What did enemies know?
- What state was the world in?
- Was the game performing correctly?
- Did the encounter behave as designed?

## Suggested event channels

- `input`
- `player_state`
- `combat`
- `damage`
- `enemy_state`
- `ai_decision`
- `world_state`
- `sector_state`
- `performance`
- `animation`
- `audio_noise`
- `debug_note`

## Developer Observatory integration

The Observatory should have:

- start recording
- stop recording
- mark moment
- export replay
- show current buffer size
- show recent critical events

Later it can provide a replay viewer.

## Acceptance criteria

Minimal implementation is acceptable when:

- A rolling event buffer exists.
- Player death triggers replay export.
- Export includes player path, damage events, enemy state changes, and FPS.
- Replay data can be opened as JSON.
- Observatory shows recording status.

## Graduation criteria

Graduate when playtesting begins producing bugs or balance questions that cannot be diagnosed from live observation alone.

## Related cards

- Developer Observatory
- Navigation and Combat Heatmaps
- Persistent World History
- World Event Timeline
- AI Morale and Cohesion System
- Performance Budget Manager

## Notes / references

This is not a player feature at first. It is a production multiplier. It turns “I think that felt bad” into evidence.
