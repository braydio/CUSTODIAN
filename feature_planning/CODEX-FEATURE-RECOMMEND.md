# CODEX-FEATURE-RECOMMEND

## Feature Name
Adaptive Relay Recovery Network (ARRN)

## Purpose
Add a high-value, reconstruction-aligned system that deepens the current loop:
- Command authority vs field presence
- Materials scarcity
- Transit risk
- Knowledge preservation as campaign identity

This feature adds meaningful choices without introducing combat complexity.

## Core Idea
Deploy and restore ancient relay nodes across transit and peripheral sectors to recover fragmented operational knowledge.

Recovered knowledge grants:
- repair efficiency bonuses
- clearer degraded information under COMMS stress
- fabrication unlock prerequisites (future)

The system makes expeditions and field presence strategically important even when materials are sufficient.

## Design Goals
1. Reinforce reconstruction fantasy over extermination.
2. Add long-term progression through knowledge, not raw stats.
3. Keep terminal-first authority and terse outputs.
4. Integrate with existing WAIT/STATUS/REPAIR/SCAVENGE loops.
5. Preserve operational ambiguity at low fidelity.

## High-Level Loop Integration
1. Detect relay opportunity through events or STATUS hint.
2. DEPLOY and MOVE through transit network.
3. Perform local relay stabilization (timed field task).
4. RETURN to command.
5. Run `SYNC` command at command center to decode relay packet.
6. Apply one bounded benefit to campaign state.

## New Commands (Phase B)
1. `SCAN RELAYS`
- Command-only.
- Lists known relay nodes and signal confidence.

2. `STABILIZE RELAY <ID>`
- Field-only, local-sector-only.
- Timed action; interrupted by movement.

3. `SYNC`
- Command-only.
- Converts stabilized packets into one knowledge unlock.

## Data Model Additions
In `GameState`:
- `relay_nodes: dict[id -> RelayNodeState]`
- `relay_packets_pending: int`
- `knowledge_index: dict[tag -> level]`
- `last_sync_time: int`

`RelayNodeState` fields:
- `sector`
- `status` (`UNKNOWN`, `LOCATED`, `UNSTABLE`, `STABLE`, `DORMANT`)
- `stability_ticks_required`
- `risk_profile`

## Authority Rules
- Command mode: scan and sync only.
- Field mode: stabilize only when in same sector.
- No recommendation text; only factual outcomes.

## Information Degradation Alignment
- COMMS fidelity affects certainty of relay state readout.
- FULL: exact node state and ticks.
- DEGRADED: approximate stability phrases.
- FRAGMENTED: `SIGNAL IRREGULAR` style output.
- LOST: relay reporting unavailable except local field context.

## Reward Model
Knowledge rewards are non-linear and bounded.

Examples:
- `MAINTENANCE_ARCHIVE_I`: remote damaged repair cost -1 minimum floor 1.
- `SIGNAL_RECONSTRUCTION_I`: improve DEGRADED STATUS fidelity for one section.
- `FAB_BLUEPRINTS_I`: prerequisite flag for future fabrication production.

No direct combat buff numbers in this phase.

## Failure/Pressure Behavior
- Failing to stabilize does not hard fail campaign.
- Delay increases opportunity cost and future assault pressure indirectly.
- Relay nodes can decay from `STABLE` to `DORMANT` if ignored for long windows.

## Implementation Plan
1. Add relay state schema and snapshot projection.
2. Add command handlers: `SCAN RELAYS`, `STABILIZE RELAY`, `SYNC`.
3. Add timed relay task integration with existing task tick loop.
4. Add STATUS section `RELAY NETWORK` with fidelity gating.
5. Add tests for authority, locality, and fidelity output behavior.
6. Add minimal UI read-only panel row for relay network state.

## Milestones
1. M1: Data-only scaffolding + STATUS exposure.
2. M2: Field stabilization task with movement constraints.
3. M3: Sync pipeline and first knowledge unlocks.
4. M4: Degradation-aware messaging and balancing pass.

## Why This Adds Value Now
- Extends current systems instead of bypassing them.
- Gives field mode strategic purpose beyond emergency repairs.
- Creates campaign continuity through knowledge recovery.
- Preserves terminal clarity and operational tone.

## Future-Compatible Extensions
- Relay-assisted expedition routing.
- Sector-specific doctrine fragments.
- Narrative logs unlocked by archive/relay intersections.
- Hub-level strategic upgrades driven by recovered knowledge quality.
