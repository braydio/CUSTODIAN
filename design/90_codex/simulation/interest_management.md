# Interest Management

Status: triaged
Category: simulation
Priority: P1
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

Entities update at different simulation fidelity based on distance, visibility, relevance, and recent player interaction.

## Problem it solves

Large living maps become expensive if every enemy, projectile, prop, and event simulates fully all the time.

## Why it fits CUSTODIAN

CUSTODIAN wants large sectors, patrols, roaming allies, persistent enemies, and environmental activity without killing performance.

## Player-facing effect

The world feels alive beyond the screen while remaining performant.

## Systems touched

Enemy AI, allied mech AI, sector simulation, ambient events, performance, save/load.

## Dependencies

Basic grouping/tagging convention for entities. Optional Developer Observatory integration.

## Risks

If done poorly, distant entities may behave inconsistently or visibly pop between states.

## Minimal version

Simulation tiers: active, nearby, background, dormant.

## Full version

Offline mathematical simulation for patrols, enemy objectives, ambient events, and resource consumption.

## Graduation criteria

Graduate when enemy count, ally behavior, or sector size begins causing performance or complexity problems.

## Notes / references

Related: Developer Observatory, Enemy Behavior Director, Ambient Scheduler, Persistent World History.

Active implementation authority: `design/01_systems/INTEREST_MANAGEMENT_SYSTEM.md` and `custodian/docs/ai_context/CURRENT_STATE.md`.

