# Grunt Loot Table

Status: draft  
Last updated: 2026-06-02

## Purpose

Starter grunt drops should be poor, practical salvage plus tiny evidence that the world is wrong. Do not make baseline human enemies drop money, generic ammo piles, or clean jackpot rewards. Their corpse should read as a broke, desperate, under-equipped person wearing the remains of a dead military system.

Design rule:

> Common drops build the base. Rare drops build the world.

Common drops help the player survive through fabrication and repair. Rare drops help the player understand what is wrong through identity, provenance, and Severance clues.

## Drop Identity

- Enemy type: low-tier hostile infantry / raider / patrol grunt
- Runtime id: `practical_salvage_x_grunt`
- Loot theme: battlefield leftovers, broken identity, corrupted provenance
- Runtime scene: `res://game/actors/enemies/enemy_grunt.tscn`

## Core Drop Table

| Resource | Player-facing name | Amount | Chance | Purpose |
|---|---|---:|---:|---|
| `ruin_scrap` | Ruin Scrap | 1-3 | 100% | Basic fabrication fuel from armor plates, weapon brackets, belt rigs, buckles, and cracked housings. |
| `spent_charge_cell` | Spent Charge Cell | 1 | 35% | Low-tier power/ammo component from a cheap sidearm battery, chest rig cell, flashlight, or targeting module. |
| `frayed_signal_filament` | Frayed Signal Filament | 1 | 20% | Sensor, terminal, and Command Center material pulled from helmet comms, respirator antennae, or squad uplinks. |
| `cracked_field_tag` | Cracked Field Tag | 1 | 15% | Lore/provenance clue for faction identity, patrol routes, assault hints, or enemy database confidence. |
| `power_components` | Power Components | 1 | 10% | Scarce repair/power routing material from better-equipped grunts or intact relay fragments. |
| `memory_glass_fragment` | Memory Glass Fragment | 1 | 4% | Rare knowledge/research item containing an impossible historical contradiction. |
| `white_thread_knot` | White Thread Knot | 1 | 1% | Rare supernatural Severance clue tied to Ash-Bell, Unarrival, or Choir-adjacent content. |

## Flavor Anchors

- Ruin Scrap: bent plating, broken fasteners, ceramic flakes, and stripped field brackets.
- Spent Charge Cell: a dull cell whose stamped manufacture date appears twice, eighteen years apart.
- Frayed Signal Filament: a hair-thin conductor that still twitches toward active transmitters.
- Cracked Field Tag: a patrol designation on one side, scraped blank and restamped with the same name in a different hand on the other.
- Power Components: tiny regulators, cracked contact pins, and a heat-warped relay.
- Memory Glass Fragment: a patrol order for a gate that local maps insist was sealed before the patrol existed.
- White Thread Knot: a clean white thread tied around the trigger finger, with no dirt, no blood, and no visible knot.

## Runtime Contract

- Enemy exports:
  - `loot_table_id = "practical_salvage_x_grunt"`
  - `loot_table = Array[Dictionary]`
- Award path:
  - If `/root/ResourceLedger` exists, each successful roll calls `ResourceLedger.add(resource_id, amount)`.
  - If the ledger is missing or no typed table is configured, the existing generic material pickup path remains available.
- Canonical resource/provenance ids are defined in:
  - `res://autoload/resource_ledger.gd`
  - `res://content/resources/resource_defs.json`

## Constraints

- Do not make baseline grunts economically rich.
- Do not make `power_components` common; power should stay scarce.
- Do not drop high-grade archive rewards from ordinary grunts except the very rare `memory_glass_fragment`.
- Keep `white_thread_knot` rare enough that it feels like a meaningful anomaly.

## Missing Future Assets

The table can already award resources, but a later physical-drop pass needs item pickup art and UI treatment for:

- `ruin_scrap`
- `spent_charge_cell`
- `frayed_signal_filament`
- `cracked_field_tag`
- `power_components`
- `memory_glass_fragment`
- `white_thread_knot`
