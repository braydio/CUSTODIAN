# Sector Activity Simulator

Status: candidate
Category: simulation
Priority: P1
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A lightweight offline simulation layer that lets distant sectors continue changing without running full gameplay logic.

## Problem it solves

A living world cannot fully simulate every enemy, patrol, repair target, resource node, ambient event, and faction conflict at all times. But if distant areas freeze completely, the world feels fake.

The Sector Activity Simulator solves this by simulating sectors at strategic fidelity when they are outside the active gameplay bubble.

## Why it fits CUSTODIAN

CUSTODIAN is about returning to ruined systems, repairing infrastructure, watching sectors recover or decay, and seeing consequences accumulate. Sectors should feel like places with ongoing conditions, not rooms waiting for the player.

This is especially useful for:

- Sundered Keep patrols
- Return Mooring recovery state
- enemy objective systems
- wave spawning
- resource depletion
- repair progress
- ambient hazards
- faction pressure

## Player-facing effect

The player leaves a sector and later returns to find believable changes.

Examples:

- A patrol moved from the gatehouse to the lower causeway.
- A damaged generator fully failed while ignored.
- A repaired beacon kept hostile wildlife away.
- A faction secured a room after the player weakened its defenders.
- An ash storm reduced visibility in an exposed region.
- A loot cache was consumed by roaming scavengers.
- Enemy pressure increased near an unrepaired relay.

## Systems touched

- Interest Management
- Enemy Objective System
- Wave Spawning
- World State Graph
- Persistent World History
- Ambient Scheduler
- Resource Economy Graph
- Save/load
- Developer Observatory
- Faction Knowledge System
- Performance Budget Manager

## Dependencies

Minimal version depends on:

- Sector identifiers
- Basic world-state keys
- Save/load
- Interest tier detection

Full version benefits from:

- World Event Timeline
- Resource Economy Graph
- Faction Knowledge System
- Line-of-Communication Graph

## Risks

Offline simulation can create confusing results if the player cannot infer why something happened.

Rules must be readable. The player should eventually understand:

- “This sector decayed because I ignored the generator.”
- “This enemy group advanced because the relay was unrepaired.”
- “This region became safer because I restored the beacon.”

Avoid arbitrary-feeling changes.

## Minimal version

Represent each sector as a simple state object:

- `sector_id`
- `danger_level`
- `power_state`
- `enemy_presence`
- `resource_level`
- `repair_stability`
- `ambient_condition`
- `last_simulated_time`

When the player is far away, update the sector every few seconds or minutes using simple rules.

Example:

- If power is offline, repair stability decays.
- If danger is high, enemy presence increases.
- If beacon is online, enemy presence slowly decreases.
- If resource level is high and enemy presence is high, scavengers may consume resources.
- If ambient condition is ash storm, visibility hazard increases.

## Full version

A full sector simulator models:

- patrol movement
- faction pressure
- resource consumption
- repairs degrading or stabilizing
- environmental hazards
- sector ownership
- enemy logistics
- reinforcement routes
- world events
- AI director pressure
- consequences of player interventions

It should not run frame-level AI. It should run “strategic truth.”

## Simulation tiers

Suggested tiers:

### Active

Full gameplay scene is loaded and simulated.

### Warm

Nearby sector. Simplified entities may continue moving. Useful for transitions.

### Strategic

No live entities. Sector state updates on timers.

### Frozen

No updates except major global events.

### Historical

Only persistent history and world state remain.

## Example rules

### Power decay

If sector power is offline:

- repair stability decreases
- door reliability decreases
- ambient danger increases
- terminals become less readable

### Beacon protection

If beacon is online:

- enemy pressure decreases
- friendly patrol chance increases
- ambient recovery chance increases

### Faction advance

If enemy pressure exceeds threshold:

- enemy presence increases
- new patrol marker activates
- sector history records `faction_advanced`

### Resource exhaustion

If sector remains hostile for long:

- resource nodes may be depleted
- containers may be broken open
- salvage quality decreases

## Developer Observatory view

The overlay should eventually display:

- sector tier
- last simulated time
- danger level
- power state
- enemy presence
- resource level
- next scheduled sector event
- why the most recent sector change happened

## Acceptance criteria

Minimal implementation is acceptable when:

- At least one inactive sector updates without being fully loaded.
- Changes are deterministic enough to save/load.
- Changes are logged to Persistent World History.
- Observatory can display sector state.
- Player-facing consequences are visible when returning.

## Graduation criteria

Graduate when the game has more than one meaningful sector and the inactive sector should not feel frozen.

## Related cards

- Interest Management
- Persistent World History
- World State Graph
- Ambient Scheduler
- Resource Economy Graph
- Line-of-Communication Graph
- Developer Observatory

## Notes / references

This is the strategic half of Interest Management. Interest Management decides how much to simulate. Sector Activity Simulator decides what actually happens while simulation is reduced.
