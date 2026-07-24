# Navigation and Combat Heatmaps

Status: graduated
Category: simulation
Priority: P1
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-21
Runtime status: runtime-seed
Runtime path: `custodian/game/systems/world/sector_heatmap.gd`
Graduated to: `design/02_features/debug_ui/NAVIGATION_COMBAT_HEATMAP_REPORTING.md`

## One-line pitch

The game records where the player moves, fights, dies, shoots, waits, and takes damage.

## Problem it solves

Level design problems are hard to diagnose from vibes. Heatmaps reveal what players actually do.

## Why it fits CUSTODIAN

CUSTODIAN has tactical combat, exploration, procedural elements, and complex spaces. Heatmaps make those spaces measurable.

## Player-facing effect

Indirect at first: better encounter tuning, better path readability, better loot placement, fewer unfair deaths.

## Systems touched

Developer telemetry, combat, level design, AI, loot, procedural generation, encounter director.

## Dependencies

Developer Observatory for visualization.

## Risks

Data can mislead if interpreted without context. Needs simple channels and clear overlays.

## Minimal version

Track player presence, damage taken, shots fired, enemy deaths, player deaths.

## Full version

AI and director use heatmaps to choose patrols, ambushes, loot placement, danger zones, and pacing adjustments.

## Graduation criteria

Graduate when playtesting starts or when level layouts need evidence-based tuning.

## Notes / references

Related: Developer Observatory, Director Memory, Encounter Language, Interest Management.

Active implementation authority: `design/02_features/debug_ui/NAVIGATION_COMBAT_HEATMAP_REPORTING.md` and `custodian/docs/ai_context/CURRENT_STATE.md`.
