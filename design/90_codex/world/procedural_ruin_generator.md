# Procedural Ruin Generator

Status: candidate
Category: world
Priority: P2
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A generator that creates coherent ruined spaces by simulating causes of failure rather than scattering random broken props.

## Problem it solves

Procedural ruins often look like noise: random cracks, random corpses, random debris, random loot. CUSTODIAN needs ruins that imply what happened.

The Procedural Ruin Generator creates damage from a cause:

- fire
- flood
- breach
- collapse
- siege
- machine failure
- temporal distortion
- evacuation
- infestation
- power overload

Then it places debris, bodies, scorch marks, broken doors, loot, and hazards accordingly.

## Why it fits CUSTODIAN

CUSTODIAN is a game about maintaining and interpreting broken systems. Ruins should be readable as failed systems.

A collapsed corridor should imply load-bearing failure. A breached gate should imply attack direction. A burned control room should imply electrical overload. A temporal chamber should imply reality distortion.

## Player-facing effect

The player sees places that feel authored even when generated.

Examples:

- A repair room has tools scattered near a broken conduit because someone died mid-repair.
- A gatehouse shows impact marks on the outside, bodies facing inward, and barricades behind the door.
- A flooded corridor contains floating debris, disabled electronics, and drowned enemies.
- A temporal breach bends props toward the anomaly and leaves memory glass fragments nearby.
- A factory overload leaves scorch trails from the generator outward.

## Systems touched

- Procedural generation
- Tilemaps
- Props
- Loot placement
- Enemy placement
- Environmental storytelling
- World Autopsy
- Persistent World History
- Material Intelligence
- Sector Heatmap
- Encounter Language
- Performance

## Dependencies

Minimal version requires:

- room/sector layout
- prop placement system
- damage theme definitions
- material tags

Full version benefits from:

- Persistent World History
- Material Intelligence System
- World Autopsy
- Resource Economy Graph
- Biome Identity Matrix

## Risks

High art/content dependency. The generator can only place what exists.

Another risk is over-randomization. Ruins need grammar. Generated destruction should follow rules players can read.

## Minimal version

Create ruin profiles.

Each profile defines:

- failure cause
- primary damage direction
- prop sets
- decal sets
- hazard sets
- loot bias
- corpse/body/remnant rules
- blocked path chance
- repair target chance
- narrative clue rules

Example profiles:

- `power_overload`
- `siege_breach`
- `water_intrusion`
- `temporal_shear`
- `abandoned_repair`
- `machine_collapse`

## Full version

The full generator runs a staged process:

1. Choose original room purpose.
2. Choose failure cause.
3. Choose failure origin.
4. Propagate damage through the space.
5. Break appropriate tiles/props.
6. Place debris based on force direction.
7. Place bodies/remnants based on escape paths.
8. Place loot based on room purpose and failure cause.
9. Place repair opportunities.
10. Emit a structured event history for World Autopsy.

## Example ruin profile

### Abandoned Repair

Purpose: maintenance room  
Failure cause: incomplete repair after evacuation  
Expected props:

- open panel
- tool crate
- loose wire
- broken relay
- dead worklight
- dropped power component

Loot bias:

- capacitor dust
- power components
- signal filament

Narrative clue:

- body or remnant near panel
- terminal error log
- partially repaired object

## Developer Observatory view

Show:

- selected ruin profile
- failure origin
- damage propagation map
- generated clue points
- loot bias
- blocked paths
- repair targets
- narrative consistency warnings

## Acceptance criteria

Minimal implementation is acceptable when:

- A room can be assigned a ruin profile.
- Props/debris/loot are placed according to profile rules.
- Damage has a visible direction or cause.
- Generated output feels more coherent than random scatter.
- Debug overlay can show the chosen profile.

## Graduation criteria

Graduate when procedural room generation exists but generated spaces need stronger narrative coherence.

## Related cards

- Persistent World History
- World Autopsy
- Material Intelligence System
- Encounter Language
- Resource Economy Graph
- Biome Identity Matrix

## Notes / references

This is where procedural generation becomes environmental storytelling rather than content shuffling.
