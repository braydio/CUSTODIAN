# World Event Timeline

Status: candidate
Category: world
Priority: P1
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A chronological timeline of major world events that can trigger sector changes, ambient events, faction behavior, repairs, failures, and narrative beats.

## Problem it solves

Without a world event timeline, global changes happen either randomly or through brittle hand-scripted triggers. CUSTODIAN needs a shared temporal layer for events that occur across the world.

## Why it fits CUSTODIAN

Time, memory, return, decay, and maintenance are central to CUSTODIAN. The world should have events that happen because time passes, systems fail, factions move, storms roll in, bells ring, and repaired infrastructure wakes up.

This is especially important for temporal zones and the Ash-Bell/Unarrival material.

## Player-facing effect

Examples:

- A bell toll marks the beginning of an anomaly window.
- A sea fog rolls in across the causeway.
- A faction assault begins after the player restores a relay.
- A repaired generator destabilizes after repeated overload warnings.
- A storm temporarily suppresses visibility and signal.
- A terminal reconstructs the sequence of events that led to a sector collapse.
- A world event triggers enemy migration.

## Systems touched

- Ambient Scheduler
- Persistent World History
- World State Graph
- Sector Activity Simulator
- Faction Knowledge System
- Director Memory
- Terminals
- Save/load
- Audio
- Lighting
- Mission generation
- Developer Observatory

## Dependencies

Minimal version requires:

- event IDs
- timestamps or world-clock ticks
- event dispatcher
- save/load

Full version benefits from:

- World State Graph
- Ambient Scheduler
- Sector Activity Simulator
- World Autopsy
- Line-of-Communication Graph

## Risks

The timeline can become too scripted and reduce systemic emergence. It should support both authored events and generated events.

Avoid making players feel punished by timers unless the game clearly communicates the risk.

## Minimal version

Create a global timeline that stores scheduled events:

- event ID
- trigger time
- scope
- event type
- payload
- fired/not fired

Example event types:

- ambient
- sector
- faction
- repair
- anomaly
- mission
- narrative

The system checks due events and emits signals.

## Full version

The full version supports:

- authored events
- generated events
- conditional events
- recurring events
- delayed consequences
- sector-local timelines
- timeline inspection in terminals
- timeline replay in Developer Observatory
- world-autopsy reconstruction from actual events
- event cancellation if the player intervenes

## Example events

### Ash Bell Toll

Scope: Forlorn Ritualant zone  
Effect: temporal distortion increases; audio layer changes; enemy behavior shifts.

### Generator Degradation

Scope: Return Mooring  
Condition: generator repaired but stabilizer not installed  
Effect: power flickers; lights become unstable; repair demand increases.

### Faction Report Spread

Scope: Sundered Keep  
Condition: scout reaches relay node  
Effect: faction knowledge updates; alert level increases.

### Sea Fog Arrival

Scope: Causeway  
Effect: visibility drops; sound propagates differently; ambush probability changes.

## Developer Observatory view

Show:

- current world time
- pending events
- recently fired events
- event source
- event scope
- canceled events
- next predicted sector event
- timeline scrubber in future full version

## Acceptance criteria

Minimal implementation is acceptable when:

- Events can be scheduled.
- Events fire at the right time.
- Fired events are recorded in Persistent World History.
- Event state saves/loads.
- Observatory displays recent and upcoming events.

## Graduation criteria

Graduate when ambient events, faction events, and world-state changes need a shared scheduling mechanism.

## Related cards

- Ambient Scheduler
- Persistent World History
- World Autopsy
- Sector Activity Simulator
- Faction Knowledge System
- Developer Replay System

## Notes / references

This is different from the Ambient Scheduler. Ambient Scheduler handles sensory/world texture. World Event Timeline handles consequential events and historical chronology.
