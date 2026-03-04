# PROJECT CONTEXT PRIMER — CUSTODIAN

**Last Updated:** 2026-03-03

## Purpose

This is the single consolidated handoff document for AI sessions.
Use it to understand current implementation state, constraints, active gaps, and high-value next steps.

**If this primer conflicts with legacy planning docs, trust `design/MASTER_DESIGN_DOCTRINE.md` and current Godot implementation.**

---

## One-Paragraph Project Summary

CUSTODIAN is a 2.5D isometric real-time tactical base defense game built on Godot 4.x. The player controls a single embodied operator (WASD) defending a static command post under siege. Gameplay combines RTS-style macro infrastructure systems with direct combat, featuring FTL-style tactical pause, deterministic systemic mechanics, and campaign-level knowledge progression.

---

## Canonical Runtime Facts

- **Engine:** Godot 4.x
- **Authority:** Godot is fully authoritative. No external simulation process.
- **Architecture:** GameState (data) → Systems (logic) → Scene (visual) → Input (commands)
- **Timing:** Fixed-step simulation (60Hz or 30Hz), render interpolation between frames
- **Pause:** FTL-style hard pause — all simulation freezes, player can issue commands
- **Time Scaling:** 1x normal, optional 2x/4x (all deterministic)

---

## Current Architecture

### Godot Project Structure (Target)

```
CUSTODIAN/
├── project.godot           # Godot project file
├── scenes/                 # Game scenes (.tscn)
│   ├── main/              # Main game scene
│   ├── operator/          # Player character
│   ├── sectors/           # Base sectors
│   ├── ui/                # Menus and HUD
│   └── combat/            # Combat entities
├── scripts/                # GDScript logic
│   ├── core/              # Core systems
│   ├── entities/           # Entity scripts
│   └── ui/                # UI scripts
├── resources/              # Assets, configs
└── export_presets.cfg     # Export configurations
```

### Core Systems (In Development)

- **Combat System:** Hitscan + projectile hybrid, damage pipeline (LOS → spread → hit → penetration → damage type → effects)
- **Power Grid:** Simulation of power distribution and load
- **Logistics:** Throughput caps and overload multipliers
- **Fabrication:** Queue system with recipes and outputs
- **Assaults:** Real-time wave spawning, approach detection, resolution
- **Relays:** ARRN network stabilization and knowledge progression

### Deprecated (Preserved for Reference)

- Python terminal interface → `custodian-terminal/`
- Python world simulation → `game/simulations/world_state/`

---

## Implemented Systems (High Confidence)

*Coming soon - in development for Godot 4.x*

---

## Current Command Surface (Operator-Relevant)

- **Movement:** WASD continuous movement
- **Combat:** Left-click (ranged), right-click (melee), E (utility)
- **Pause:** Spacebar or Escape for tactical pause
- **Camera:** Pan (edge or middle mouse), zoom (scroll)
- **Systems:** Pause menu for policy, fabrication, relay management

---

## Known High-Value Gaps

1. **Combat prototype** — Core ranged/melee mechanics need implementation
2. **Sector system** — Base sector layout and navigation
3. **Assault wave AI** — Enemy spawning and behavior
4. **Power/logistics systems** — Infrastructure simulation
5. **Save system** — Deterministic state serialization

---

## Focus Areas for Next-Step Recommendations

1. **Combat feel** — Implement and tune operator combat (hitscan, projectiles, melee)
2. **Sector navigation** — Isometric movement and collision within base
3. **Assault foundation** — Basic enemy spawning and threat detection
4. **Systems skeleton** — Power, logistics, fabrication as data-driven systems

---

## Guardrails for Any New Work

- Keep logic separate from rendering nodes
- Maintain fixed-step deterministic simulation
- Preserve Godot-authoritative model
- Use GDScript or Godot-compatible languages only
- No external runtime processes

---

## Session Start Checklist

1. Read `design/MASTER_DESIGN_DOCTRINE.md`
2. Read this primer
3. Verify requested feature against current implementation
4. Prefer incremental prototyping with playable builds
5. Update relevant design docs when behavior changes

---

## Validation Baseline

Primary baseline: **Open project.godot in Godot 4.x and run**

Run tests if applicable:

```bash
# Godot headless test execution (if configured)
godot --headless --script tests/run.gd
```
