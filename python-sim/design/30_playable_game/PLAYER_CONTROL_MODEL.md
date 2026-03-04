# PLAYER CONTROL MODEL

Status: Active
Last updated: 2026-03-04

## Core Control Contract

The player controls one embodied operator in real-time.

- `W/A/S/D` -> movement
- `Pause` action (Space by default) -> hard tactical pause toggle

## Combat and Interaction Targets

- Ranged slot: primary direct-fire actions
- Melee slot: close-range deterministic strike windows
- Utility slot: repair, relay interaction, and system-focused actions

Final input bindings may evolve, but the three-slot interaction model is locked.

## Pause Behavior

- Pause freezes simulation mutation globally.
- Player can still issue planning/management actions while paused.
- Unpause resumes deterministic fixed-step processing.

## Camera and Spatial Read

- Isometric-bias camera with pan/zoom.
- Input and camera must preserve tactical readability in dense sector interiors.

## Authority Rules

- Input creates intents.
- Systems validate intents against state constraints.
- GameState mutation happens in simulation systems, not directly in scene/UI code.

## Legacy Note

This document replaces terminal-command-first control semantics as the active player model.
Legacy command surfaces remain reference-only in `python-sim/game/simulations/world_state/`.
