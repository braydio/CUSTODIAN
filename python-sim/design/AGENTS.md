# AGENTS.md

## CUSTODIAN Design Governance (Post-Pivot)

CUSTODIAN is now Godot-native for active runtime. Design docs remain in `python-sim/design/`.

## Canonical Layers

### Active Code Layer

- `custodian/` (Godot 4.x project)

### Design Layer (Canonical)

- `python-sim/design/`

### AI Projection Layer

- `python-sim/ai/`

## Document Hierarchy

- `00_foundations/`: locked architecture/timing/identity principles
- `10_systems/`: system-level design references
- `20_features/{planned,in_progress,completed}`: lifecycle tracking
- `30_playable_game/`: playable/runtime model docs
- `archive/`: historical and deprecated docs

## Terminal Deprecation Rule

Terminal-command and `/command` transport docs are deprecated as active runtime contracts.
Archive these under:

- `python-sim/design/archive/terminal-deprecated/`

## Update Rules

Whenever active architecture/behavior changes:

1. Update relevant design docs.
2. Update `design/CHANGELOG.md`.
3. Update `design/DEVLOG.md`.
4. Update `ai/CURRENT_STATE.md`.
5. Ensure active-vs-legacy labels remain accurate.

## Determinism Rule

- Fixed-step simulation logic must remain deterministic.
- If determinism constraints change, update `00_foundations/SIMULATION_RULES.md`.

## Final Principle

CUSTODIAN remains systems-first and deterministic, now executed in a Godot-authoritative runtime with an embodied operator control model.
