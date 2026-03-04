# CUSTODIAN — MASTER DESIGN DOCTRINE v2.0

> **This document formally locks the core design decisions for CUSTODIAN. It supersedes all prior architecture assumptions.**

**Last Updated:** 2026-03-03
**Status:** LOCKED

---

# I. Core Identity

CUSTODIAN is a 2.5D isometric real-time tactical base defense game with a directly controlled operator.

It combines:

- RTS-style macro infrastructure systems
- A single embodied operator (WASD controlled)
- FTL-style tactical pause
- Deterministic systemic mechanics
- Campaign-level knowledge and progression

The game is not terminal-first. The terminal mode is one interface layer among others.

The primary mode is isometric real-time tactical gameplay.

---

# II. Engine & Authority

## Engine

- Godot 4.x
- 2.5D isometric presentation (2D scene using isometric projection)
- Stylized minimal / schematic industrial art direction

## Authority Model

Godot is fully authoritative.

There is no external runtime simulation process.

However:

- Simulation logic must be separated from rendering nodes.
- Game logic must not live inside view components.
- Systems must be modular and testable in isolation.

Architecture principle:

```
GameState (pure data)
Systems (pure logic)
Scene (visual representation)
Input (translated into commands)
```

Rendering reads state.
Systems mutate state.
Scenes do not own logic.

---

# III. Timing Model

Simulation uses a hybrid model:

- Fixed-step simulation loop (e.g., 60Hz or 30Hz).
- Render loop interpolates visually between simulation frames.
- All combat, damage, power, logistics, relays, and AI operate on fixed-step.

Pause Model:

- Full FTL-style hard pause.
- All simulation freezes.
- Player can issue commands while paused.
- Projectiles, AI, and power systems freeze.

Time scaling:

- 1x normal
- Optional 2x / 4x
- All simulation remains deterministic under scaling.

---

# IV. Spatial Model

Macro Layer:

- Sector grid layout (static base structure).
- Sectors are logical units: Command, Power, Defense, Archive, etc.

Micro Layer:

- Continuous movement inside sector.
- Operator controlled via WASD.
- Collision map per sector.
- Isometric Y-sort enabled.

No camera rotation.
Camera supports:

- Pan
- Zoom
- Fixed isometric angle

---

# V. Combat Model

## Operator

One embodied operator with:

- Melee weapon slot
- Ranged weapon slot
- Utility tool slot

Upgradeable across campaign.

---

## Ranged Combat

Model:

- Hybrid system.
- Hitscan for standard weapons.
- Physical projectiles for heavy weapons.

Accuracy:

- Hybrid model.
- Base spread cone (skill-based aim).
- Stat modifiers affecting spread, recoil, penetration.

Damage Pipeline:

1. Check line-of-sight.
2. Apply spread deviation.
3. Determine hit.
4. Apply penetration vs armor.
5. Apply damage type.
6. Trigger status effects (if any).

Damage types may include:

- Kinetic
- Thermal
- Disruption
- Structural

---

## Melee

- Range check.
- Cooldown based.
- Deterministic damage.
- Can interact with destructible environment.

---

## Utility Tool

Non-lethal systemic interaction:

- Repair structures
- Interface with relay nodes
- Stabilize sectors
- Interact with fabrication

Utility upgrades expand systemic capability, not raw DPS.

---

# VI. RTS Layer Scope

Scope Level: A

CUSTODIAN includes:

- Base defense systems
- Infrastructure policy control
- Relay network management
- Fabrication queue
- Power distribution
- Logistics caps

No squad-level RTS control at launch.

The operator is the only controllable unit.

AI-controlled defense systems operate autonomously.

Future expansions may add limited deployables.

---

# VII. Systems Layer

The following systems are active and persistent:

- Power grid simulation
- Logistics throughput model
- Fabrication system
- Assault wave resolution
- Relay stabilization and knowledge progression
- Structural damage propagation

All systems operate continuously in real-time fixed-step.

---

# VIII. Assault Model

Assaults occur in real-time.

Flow:

1. Recon signals detected.
2. Escalation indicators increase.
3. Assault begins.
4. Enemy entities spawn at sector ingress.
5. Operator defends while base systems respond.
6. Damage propagates structurally.
7. Assault ends.
8. Aftermath stabilization phase begins.

Aftermath events emphasize recovery and assessment.

---

# IX. Progression Model

Upgrade Model: C (Hybrid)

## Campaign Meta

Permanent upgrades:

- Weapon classes unlocked
- Utility capabilities expanded
- Relay knowledge milestones
- Infrastructure efficiencies

## Run-Level

Temporary upgrades:

- Fabrication unlocks
- Sector improvements
- Temporary stat boosts

Knowledge progression remains a central pillar.

ARRN relay system integrates into campaign meta unlocks.

---

# X. Persistence Model

Save Model: A

- Save anytime.
- Mid-assault saves allowed.
- Ironman mode optional.
- State serialization must capture:

  - All entities
  - Sector states
  - Projectile states
  - Cooldowns
  - Power distribution
  - Relay states
  - Campaign flags

Deterministic state reconstruction required.

---

# XI. Art Direction

Stylized Minimal / Schematic Industrial

Characteristics:

- Clean silhouettes
- Subtle glow lines for power/logistics
- Industrial geometry
- Muted palette
- Limited animation noise
- Clear readability at zoomed-out levels

No photorealism.
No heavy particle clutter.

Visual clarity over spectacle.

---

# XII. Core Design Pillars

1. Reconstruction over extermination.
2. Information is power.
3. Systems interact visibly.
4. Operator embodiment enhances — not replaces — systemic gameplay.
5. Tactical pause is a strategic tool.
6. Upgrades expand capability, not inflate raw stats.
7. The base feels like a machine under stress.

---

# XIII. Development Doctrine

- Build Godot-native.
- Keep logic separate from rendering.
- Prototype combat early.
- Validate feel before deep feature layering.
- Preserve systemic clarity.
- Avoid over-expanding RTS layer prematurely.

---

# XIV. Scope Guardrails

CUSTODIAN is:

- Tactical
- Systemic
- Embodied
- Strategic

CUSTODIAN is not:

- Squad-based RTS (at launch)
- Action shooter
- Roguelite stat-inflation treadmill
- Pure base-builder sandbox

---

# XV. Identity Reaffirmed

CUSTODIAN is a tactical systems defense game with embodied presence.

The player is not a general commanding units.

The player is the last operator inside a failing machine,
choosing what must be preserved.

---

# XVI. Legacy Terminal Interface

The Python terminal interface is deprecated but preserved as a secondary interface for:

- Debug/diagnostic purposes
- Legacy command-line operation
- Deterministic testing reference

The terminal is no longer the primary interface. All new development targets Godot-native gameplay.

---

*This document is LOCKED. Design changes require explicit review and version bump.*
