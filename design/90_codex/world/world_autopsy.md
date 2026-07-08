# World Autopsy

Status: candidate
Category: world
Priority: P0
Maturity: system
Cost: high
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

The world reconstructs its own history from simulation data rather than scripted lore.

## Problem it solves

Environmental storytelling usually requires handcrafted notes and audio logs. This system generates believable history automatically.

## Why it fits CUSTODIAN

The Custodians exist to maintain civilization after its collapse. Recovering forgotten events is central to that fantasy.

## Player-facing effect

Repairing a terminal allows it to reconstruct local events.

Example:

07:14 - Generator overload detected.

07:16 - Bulkhead sealed.

07:19 - Four unidentified entities entered Sector B.

07:22 - Emergency shutdown initiated.

07:25 - No remaining personnel detected.

## Systems touched

Persistent History, World State Graph, terminals, save system, sector simulation.

## Dependencies

Persistent World History.

## Risks

Needs event filtering so terminals do not become unreadable.

## Minimal version

Generate chronological logs from stored world events.

## Full version

Confidence ratings, damaged logs, conflicting reports, partial reconstructions, timeline visualization.

## Graduation criteria

Graduate when terminals become major gameplay interactions.

## Notes / references

Could become one of CUSTODIAN's defining mechanics.

Related: Persistent World History, World State Graph, Developer Observatory.

