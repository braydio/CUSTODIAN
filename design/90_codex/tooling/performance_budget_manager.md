# Performance Budget Manager

Status: candidate
Category: tooling
Priority: P1
Maturity: system
Cost: medium
Owner: Brayden
Last reviewed: 2026-07-08

## One-line pitch

A live system that tracks CPU, GPU, entity, AI, physics, particles, animation, and memory budgets so performance problems are visible before they become disasters.

## Problem it solves

Performance problems often accumulate invisibly. A few enemies, particles, lights, large sprite sheets, pathfinding calls, and process loops each seem fine until the game starts hitching.

CUSTODIAN needs a budget system that tells the developer:

- too many active enemies
- too many full-rate AI updates
- too many particles
- too many expensive lights
- too many animated sprites
- too many physics bodies
- large runtime sheets loaded directly
- too many pathfinding requests
- too much debug drawing
- too many projectiles

## Why it fits CUSTODIAN

The game is heading toward large tactical spaces, animated characters, ranged combat, procedural sectors, ambient effects, large tilemaps, and simulation systems. Without budgets, it will become hard to tell whether a problem is art, AI, rendering, pathfinding, particles, or world simulation.

## Player-facing effect

Indirect: smoother performance, more enemies on screen, fewer hitches, better responsiveness, cleaner combat feel.

## Systems touched

- Developer Observatory
- Interest Management
- AI
- Combat
- Particles
- Animation
- Tilemaps
- Asset pipeline
- Rendering
- Physics
- Audio
- Save/load
- Build validation

## Dependencies

Minimal version requires:

- counters
- gauges
- frame time sampling
- entity groups

Full version benefits from:

- Developer Observatory
- Interest Management
- Animation asset pipeline
- Sector Activity Simulator
- Build validation scripts

## Risks

Can become noisy if every metric is displayed constantly. The budget manager should prioritize warnings and thresholds, not walls of numbers.

Avoid optimizing too early. The goal is visibility first, enforcement later.

## Minimal version

Track:

- FPS
- frame time
- active enemies
- active projectiles
- active particles
- active physics bodies
- active animated sprites
- interest-managed active/nearby/background/dormant counts
- loaded texture memory estimate if available
- AI updates per second
- pathfinding requests per second

Display warnings when thresholds are exceeded.

## Full version

Full version adds:

- per-sector budgets
- per-system timing
- budget profiles
- runtime enforcement
- automatic interest-tier downgrade
- particle culling
- AI update throttling
- asset sheet warnings
- frame spike capture
- replay correlation
- exportable performance reports
- CI/build validation checks

## Suggested initial budgets

These are placeholders and should be tuned after real profiling.

### Runtime

- target FPS: 60
- warning FPS: below 50
- critical FPS: below 40

### AI

- active enemies: warning above 24
- active enemies: critical above 40
- AI decisions per second: warning above 200

### Combat

- active projectiles: warning above 80
- active hitboxes: warning above 80

### FX

- active particles: warning above 300
- active lights: warning above 24

### Simulation

- interest-managed active entities: warning above 60
- background entities: warning above 500

## Developer Observatory view

Add a Performance tab:

- FPS
- frame time graph
- warnings
- active counts
- interest tier counts
- AI update count
- projectile count
- particle count
- pathfinding count
- top recent frame spikes

## Acceptance criteria

Minimal implementation is acceptable when:

- It displays live counts in Developer Observatory.
- It warns when configured thresholds are exceeded.
- It samples frame time.
- It tracks interest-tier counts.
- It can export a simple performance snapshot.

## Graduation criteria

Graduate before large combat encounters, large maps, or heavy FX passes.

## Related cards

- Developer Observatory
- Interest Management
- Sector Activity Simulator
- Developer Replay System
- Material Intelligence System
- Animation Asset Workflow

## Notes / references

This system should prevent “death by a thousand cool features.” Every new feature should eventually have a budget line.
