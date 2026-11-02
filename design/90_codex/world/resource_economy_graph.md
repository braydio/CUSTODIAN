# Resource Economy Graph

Status: candidate
Category: world
Priority: P1
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A graph-based model of resources, production, consumption, shortage, repair demand, salvage, and logistics across CUSTODIAN sectors.

## Problem it solves

Resources can easily become generic crafting tokens. CUSTODIAN needs resources to feel like infrastructure: things are produced, consumed, lost, repaired, stolen, rerouted, depleted, and fought over.

The Resource Economy Graph gives resources context and pressure.

## Why it fits CUSTODIAN

The player is a custodian, not just a scavenger. That implies maintenance economics:

- What needs power?
- What consumes parts?
- Which sector lacks structural alloy?
- Which relay needs signal filament?
- What happens if repair demand exceeds supply?
- Why do enemies steal specific materials?
- What does restoring a facility actually produce?

Your existing resource concepts already point toward this:

- ruin scrap
- structural alloy
- power components
- resin clot
- capacitor dust
- signal filament
- memory glass fragment

The graph makes those resources matter beyond inventory.

## Player-facing effect

The player starts to understand the world as a damaged logistics system.

Examples:

- Repairing a power station increases power component production.
- Restoring a signal tower reduces signal filament scarcity.
- Losing a salvage depot causes turret repairs to stall.
- Enemy raiders target structural alloy because they need fortifications.
- A terminal can say: “Repair demand exceeds available capacitor dust.”
- Certain routes become valuable because they reconnect supply.

## Systems touched

- Inventory
- Repair Gameplay
- World State Graph
- Enemy Objective System
- Vault theft
- Sector Activity Simulator
- Faction AI
- Procedural loot
- Terminals
- Save/load
- Developer Observatory
- Mission generation

## Dependencies

Minimal version requires:

- Canonical resource IDs
- Sector IDs
- Repair costs
- Basic world-state keys

Full version benefits from:

- Line-of-Communication Graph
- Sector Activity Simulator
- Faction Knowledge System
- World Event Timeline

## Risks

The main risk is making the game feel like a spreadsheet. The economy should support tactical survival and world meaning, not become a management sim unless deliberately chosen.

Another risk is overcomplication. Start with resource pressure, not full production chains.

## Minimal version

Track each sector’s resource situation:

- supply
- demand
- scarcity
- production sources
- repair sinks

Example sector data:

- Return Mooring produces small amounts of signal stability after beacon repair.
- Sundered Keep consumes structural alloy for gate repairs.
- Industrial platforms produce power components if reactivated.
- Temporal zones produce memory glass but increase anomaly risk.

## Full version

The full graph contains:

- nodes: sectors, depots, generators, relays, terminals, factories
- edges: routes, power lines, signal paths, supply chains
- resources: salvage, power, signal, alloy, memory, resin
- consumers: repairs, turrets, doors, terminals, NPC needs, enemy fortifications
- producers: salvage sites, restored factories, defeated machines, recovered caches
- losses: enemy theft, decay, disasters, world events

This can drive missions:

- “Restore relay to reconnect signal supply.”
- “Recover stolen power components before sector blackout.”
- “Repair logistics route to unlock turret maintenance.”
- “Defend the depot while it fabricates gate parts.”

## Suggested resource roles

### Ruin Scrap

Generic salvage. Broad repair filler. Low narrative specificity.

### Structural Alloy

Doors, gates, bridges, barricades, platforms.

### Power Components

Generators, terminals, turrets, lighting, elevators.

### Resin Clot

Organic/temporal sealing, biological repair, strange growths.

### Capacitor Dust

High-energy electronics, unstable machine repairs, weapon systems.

### Signal Filament

Communications, beacons, guidance, AI coordination.

### Memory Glass Fragment

World Autopsy, archival systems, temporal reconstruction, high-value lore systems.

## Developer Observatory view

The overlay should eventually show:

- resource supply by sector
- demand by repair target
- shortages
- production nodes
- consumption nodes
- theft/loss events
- disconnected graph edges
- resource bottlenecks

## Acceptance criteria

Minimal implementation is acceptable when:

- A sector can define resource supply and repair demand.
- A terminal can report shortage/sufficiency.
- Repair targets can consume resources from a defined pool.
- World state changes can alter supply/demand.
- Observatory can display resource pressure.

## Graduation criteria

Graduate when repair gameplay, vault theft, or mission generation needs resources to mean more than inventory counts.

## Related cards

- World State Graph
- Repair Gameplay System
- Line-of-Communication Graph
- Sector Activity Simulator
- Enemy Objective System
- Persistent World History
- World Autopsy

## Notes / references

This system should be kept player-legible. The player does not need to see every number, but they should feel that materials have purpose, scarcity, and consequence.
