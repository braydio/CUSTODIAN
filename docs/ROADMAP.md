# Roadmap

This roadmap focuses on simulation-first development. Each phase ends with a text-mode prototype that can be evaluated quickly and iterated in code before any engine work.

## Guiding Constraints

- Keep the base static and sectorized.
- Preserve the command-center vs field asymmetry.
- Maintain knowledge-first progression and reconstruction goals.
- Avoid premature 3D scope; 2.5D presentation can wait.

## Phase 1: World-State Loop (Now)

Goal: a stable, readable text simulation of ambient pressure and assaults.

### Deliverables

- `GameState` with time, ambient threat, assault timer, faction profile, and sector states.
- Event catalog driven by ideology/form/tech expression.
- Ambient event ticking with cooldowns and sector filters.
- Assault trigger and resolution against weak sectors.
- Snapshot output that is terse and operational.

### Exit Criteria

- Running `python game/simulations/world_state/sandbox_world.py` produces:
  - Quiet stretches.
  - Escalation feels earned.
  - Assaults occur without explicit timers.
  - Sector damage and alertness have visible impact.

## Phase 2: Assault Resolution Prototype

Goal: connect assaults to clear outcomes and data-driven enemy groups.

### Deliverables

- Assault group composition data (threat points, roles, behavior tags).
- Morale rules wired to assault resolution.
- Sector defense effectiveness model (power, alertness, damage).
- Loss conditions applied to Command Center and Goal Sector.

### Exit Criteria

- Assaults are repeatable and tuneable.
- Threat composition produces different outcomes with the same base layout.

## Phase 3: Command Center + Power Routing

Goal: model the command-center advantage and power scarcity in simulation output.

### Deliverables

- Power budget and routing model across sectors.
- Command Center actions that alter power priorities.
- Field limitations (no global reroute, only local toggles).
- Autopilot behavior uses only powered systems.

### Exit Criteria

- Output shows meaningful tradeoffs from being in or out of Command Center.
- Power loss produces predictable, fair failure modes.

## Phase 4: Recon & Knowledge Progression

Goal: connect recon runs to knowledge, power cells, and faction escalation.

### Deliverables

- Recon state machine (depart, field, return).
- Knowledge fragments and synthesis unlocks.
- Strategic power cell recovery loop.
- Campaign goal templates seeded per run.

### Exit Criteria

- Recon runs meaningfully alter ambient threat, assault timing, and unlocks.
- Knowledge changes future enemies and available systems.

## Phase 5: Tutorial Campaign Pass

Goal: lock a teachable, semi-scripted first campaign.

### Deliverables

- Tutorial pacing tied to the first assault spec.
- Sector rules and travel time implications.
- Mission objectives for rebuild-to-escape.

### Exit Criteria

- A full tutorial run can be simulated end-to-end in text.

## Phase 6: Presentation Prototype (Optional)

Goal: experiment with 2.5D visualization without altering core logic.

### Deliverables

- Isometric or fixed-camera rendering stub.
- Readable sector overlays and event output.

### Exit Criteria

- Visual layer consumes the same simulation outputs.

## Open Questions (Resolve Before Phase 4)

- Final base form factor choice (sectorized static outpost is preferred).
- First reconstruction objective type (archive, network, AI, or defense system).
- Early combat lethality target (tactical, lethal-but-forgiving, or arcade).
