# Line-of-Communication Graph

Status: candidate
Category: world
Priority: P1
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A graph representing routes, signal lines, power lines, logistics paths, relay coverage, and faction communication between sectors.

## Problem it solves

World systems need a shared way to answer:

- Can this sector receive power?
- Can this faction report the player's location?
- Can resources move from one depot to another?
- Can enemy reinforcements reach this room?
- Does repairing this relay reconnect anything important?
- Does destroying this bridge isolate a sector?

Without a communication/logistics graph, each system invents its own connectivity logic.

## Why it fits CUSTODIAN

CUSTODIAN is about restoring broken infrastructure. A Line-of-Communication Graph makes infrastructure concrete.

It turns repairs into reconnection.

The player does not just fix a box. They restore a route, signal path, supply link, or power line.

## Player-facing effect

Examples:

- Repairing a relay makes a terminal readable two sectors away.
- Destroying a bridge prevents enemy reinforcements.
- Restoring a power conduit activates lights along a route.
- Severing a comms mast prevents a faction from spreading alerts.
- Opening an old maintenance tunnel creates a new logistics path.
- A map terminal shows “signal route incomplete.”

## Systems touched

- World State Graph
- Resource Economy Graph
- Faction Knowledge System
- Enemy Objective System
- Sector Activity Simulator
- Repair Gameplay
- Terminals
- Map UI
- Mission generation
- Save/load
- Developer Observatory

## Dependencies

Minimal version requires:

- Sector IDs
- Node IDs
- Edge definitions
- Edge state open/closed/disabled/repaired

Full version benefits from:

- World State Graph
- Resource Economy Graph
- Faction Knowledge System
- Procedural generation

## Risks

Graph systems can become abstract and disconnected from the physical level. Every graph edge should correspond to something visible or inferable:

- bridge
- corridor
- cable
- relay mast
- power conduit
- elevator
- gate
- causeway
- signal tower
- maintenance tunnel

Avoid invisible graph magic.

## Minimal version

Define graph nodes:

- sectors
- relays
- gates
- depots
- terminals
- generators

Define graph edges:

- route
- power
- signal
- logistics

Each edge has state:

- active
- broken
- locked
- hostile_controlled
- repaired
- unknown

Then systems ask the graph:

- Is there an active signal path from terminal to relay?
- Is there a route from enemy depot to player sector?
- Is resource movement possible between sectors?
- Is this sector isolated?

## Full version

A full graph supports:

- multiple edge types
- traversal costs
- faction ownership
- signal strength
- power capacity
- logistics throughput
- sabotage
- temporary blockages
- world events altering connectivity
- repair missions generated from bottlenecks
- map UI overlays
- sector isolation consequences

## Example edge types

### Route edge

Represents physical movement.

Used by:

- enemies
- player navigation
- reinforcements
- patrols

### Power edge

Represents electrical/energy flow.

Used by:

- lights
- doors
- terminals
- turrets
- elevators

### Signal edge

Represents communications/data flow.

Used by:

- terminal access
- faction alerts
- World Autopsy
- map updates
- objective discovery

### Logistics edge

Represents resource movement.

Used by:

- Resource Economy Graph
- repair supply
- enemy resupply
- sector recovery

## Developer Observatory view

Show graph overlay with:

- active nodes
- broken nodes
- active edges
- blocked edges
- edge type filters
- faction ownership
- signal/power/logistics flow
- disconnected components
- bottlenecks

## Acceptance criteria

Minimal implementation is acceptable when:

- The graph can represent at least three connected sectors.
- Repairing a relay changes graph connectivity.
- A terminal/door/faction query can use the graph.
- Observatory can print or visualize current graph connectivity.
- Graph state saves/loads.

## Graduation criteria

Graduate when two or more systems need shared connectivity: for example power + faction reports, or repair supply + enemy reinforcements.

## Related cards

- World State Graph
- Resource Economy Graph
- Faction Knowledge System
- Sector Activity Simulator
- Repair Gameplay System
- Developer Observatory

## Notes / references

This could become the hidden skeleton of CUSTODIAN’s world design. It makes “Return to post” mechanically literal: restore the broken lines.
