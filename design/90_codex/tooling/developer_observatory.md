# Developer Observatory

Status: candidate
Category: tooling
Priority: P0
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A debug observatory that visualizes invisible simulation state, telemetry, heatmaps, AI behavior, world events, and runtime health.

## Problem it solves

CUSTODIAN has too many interacting systems to debug by intuition alone.

## Why it fits CUSTODIAN

The game is about maintenance, diagnosis, signal, forgotten systems, and buried truth. A developer observatory mirrors the game's own themes.

## Player-facing effect

Indirect but massive: better combat balance, clearer levels, fewer invisible bugs, stronger encounters.

## Systems touched

Debug UI, telemetry, AI, combat, heatmaps, world state, performance, player analytics.

## Dependencies

None for minimal version.

## Risks

Can become too broad. Must begin as a simple F9 overlay.

## Minimal version

F9 overlay showing FPS, player position, active enemy count, recent debug events, damage logs, death logs, and current world-state values.

## Full version

Vision cones, sound propagation, tile heatmaps, AI state labels, sector ownership, world-state graph, simulation tiers, resource flows, event replay, and performance counters.

## Graduation criteria

Graduate when at least two runtime systems need shared debug visibility.

## Notes / references

Related: Sector Heatmap, Persistent World History, World State Graph, Interest Management.

Active implementation authority: `design/02_features/debug_ui/DEVELOPER_OBSERVATORY_SYSTEM.md` and `custodian/docs/ai_context/CURRENT_STATE.md`.

