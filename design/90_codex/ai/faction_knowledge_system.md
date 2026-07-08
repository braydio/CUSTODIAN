# Faction Knowledge System

Status: candidate
Category: ai
Priority: P1
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

Each faction tracks what it knows about the player, sectors, resources, threats, repairs, and other factions, then acts on imperfect information.

## Problem it solves

Enemy behavior often feels omniscient or random. The Faction Knowledge System gives factions believable memory and uncertainty.

Instead of “enemy magically knows where the player is,” the faction has knowledge:

- last seen location
- suspected route
- known repaired systems
- known resource caches
- known player weapon preference
- known losses
- known safe paths
- unknown sectors

## Why it fits CUSTODIAN

CUSTODIAN’s world should feel like damaged systems and hostile groups are trying to interpret each other through broken signals, patrol reports, sensors, stolen data, and rumor. Knowledge should be incomplete, delayed, and faction-specific.

A machine faction may know power-grid events. A scavenger faction may know loot caches. A temporal faction may react to memory-glass disturbances.

## Player-facing effect

The player can mislead, avoid, provoke, or reveal themselves to factions.

Examples:

- A patrol reports the Operator using a rifle.
- Later enemies bring shields.
- If the player restores a beacon quietly, some factions do not react.
- If a terminal broadcast goes online, nearby machine factions become aware.
- If the player repeatedly raids one route, a faction starts guarding it.
- If scouts are killed before escaping, the faction does not learn.
- If a camera sees the player, the faction updates its known location.

## Systems touched

- Enemy AI
- Director Memory
- Sector Activity Simulator
- World State Graph
- Combat telemetry
- Stealth/noise
- Patrols
- Terminals
- Faction objectives
- Save/load
- Developer Observatory

## Dependencies

Minimal version requires:

- Faction IDs
- Event logging
- Player behavior telemetry
- Enemy report events

Full version benefits from:

- Director Memory
- Line-of-Communication Graph
- Sound Propagation
- Sector Activity Simulator

## Risks

Can become invisible. If factions adapt but the player cannot infer why, it may feel like cheating.

The system needs telltales:

- radio chatter
- terminal reports
- scout behavior
- visible reinforcements
- faction-specific countermeasures
- World Autopsy logs showing reports

## Minimal version

Track simple faction knowledge values:

- `last_known_player_position`
- `player_weapon_bias`
- `player_repair_activity`
- `known_sector_power_states`
- `alert_level`
- `recent_losses`
- `known_resource_targets`

Faction knowledge updates from events:

- player spotted
- gunshot heard
- scout escaped
- terminal activated
- patrol destroyed
- repair completed
- resource stolen/recovered

## Full version

Faction knowledge becomes a blackboard layer per faction.

It contains:

- confirmed facts
- suspected facts
- stale facts
- confidence values
- report sources
- knowledge propagation through communication routes
- deliberate misinformation
- faction-specific interpretation

Example:

A machine faction may treat `power_restored` as high-confidence because it senses the grid. A scavenger faction may only learn through scouts. A temporal faction may know about memory-glass usage but not normal doors.

## Knowledge confidence

Suggested confidence tiers:

- `confirmed`
- `likely`
- `suspected`
- `rumor`
- `unknown`

Knowledge should decay or become stale.

Example:

- Last seen player position is confirmed for 10 seconds.
- Likely for 60 seconds.
- Suspected after that.
- Unknown if no contact occurs.

## Developer Observatory view

Show per-faction:

- alert level
- last known player position
- known repaired systems
- known resource targets
- current objective
- confidence levels
- how the faction learned something
- active reports traveling through the world

## Acceptance criteria

Minimal implementation is acceptable when:

- At least one faction remembers the player's last known position.
- Player weapon behavior updates a faction preference/countermeasure value.
- Faction alert level changes based on reports.
- Killing a scout before report prevents knowledge transfer.
- Observatory can display faction knowledge.

## Graduation criteria

Graduate when multiple enemy types or factions need to react differently to the player over time.

## Related cards

- Director Memory
- Enemy Behavior Director
- Line-of-Communication Graph
- Sector Activity Simulator
- Developer Observatory
- World Autopsy

## Notes / references

This system should feel like enemies are learning through the world, not like the game is punishing the player through invisible difficulty scaling.
