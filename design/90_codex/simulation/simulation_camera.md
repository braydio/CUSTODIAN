# Simulation Camera

Status: candidate
Category: simulation
Priority: P2
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

Invisible observers continuously record player behavior for analytics.

## Problem it solves

Player behavior is difficult to understand during testing.

## Why it fits CUSTODIAN

Supports balancing while remaining invisible during gameplay.

## Player-facing effect

None directly. Indirectly improves every encounter.

## Systems touched

Telemetry, Developer Observatory, combat, AI.

## Dependencies

Developer Observatory.

## Risks

Collecting too much data.

## Minimal version

Track movement, deaths, weapon usage, healing, and time spent.

## Full version

Cluster player archetypes and generate playstyle reports.

## Graduation criteria

Graduate before large-scale playtesting.

## Notes / references

Metadata note: supplied as an experiment card; maturity is normalized to `system` to match codex values because the implementation shape is clear.

Related: Developer Observatory, Navigation and Combat Heatmaps, Director Memory.

