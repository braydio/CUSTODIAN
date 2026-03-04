# CORE DESIGN PRINCIPLES — CUSTODIAN

Status: Active
Last updated: 2026-03-04

## 1) Reconstruction Over Extermination

The player goal is preservation and recovery of knowledge under pressure.
Systems, rewards, and mission outcomes must bias toward stabilization and recovery decisions.

## 2) Embodied Operator + System Command

The operator is physically present in the base (WASD control) while still managing macro systems.
Direct action and systems control are complementary, not separate game modes.

## 3) Godot-Authoritative Deterministic Simulation

- Game rules execute in fixed-step simulation.
- Rendering does not own mechanics.
- State mutation must be deterministic for equivalent seed + input sequences.

## 4) Static Facility, High Tactical Depth

CUSTODIAN is a static command post defense model.
Depth comes from sector geometry, chokepoints, subsystem coupling, and assault response.

## 5) Readability First (Isometric Combat Space)

- 2.5D isometric presentation must prioritize tactical readability.
- Camera behavior and UI should expose pressure, damage, and system state clearly.
- Visual complexity must not hide decision-critical information.

## 6) Hard Constraints Drive Decisions

Power, logistics, fabrication throughput, and relay status must remain real constraints.
The player should not be able to optimize all systems simultaneously.

## 7) Tactical Pause is a Strategic Tool

Pause freezes simulation while enabling planning and command decisions.
Pause is not optional polish; it is part of core control language.

## 8) Legacy Python Stack Is Reference-Only

Terminal-first command runtime is deprecated for primary gameplay.
Legacy docs and code are retained for migration context and deterministic behavior references.
