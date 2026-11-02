# GDScript Coding Standards

Last updated: 2026-03-04

## Design Goals

- Deterministic behavior
- Clear ownership boundaries
- Small, readable scripts

## Style Rules

- Use explicit constants for tunables (e.g., `FIXED_DT`, movement speeds).
- Keep one responsibility per script when practical.
- Prefer descriptive names over abbreviations.
- Keep comments sparse and high-value.

## Runtime Rules

- Do not mutate gameplay state from UI-only scripts.
- Do not put simulation rules in scene-only view scripts unless script is an entity/system actor.
- Prefer fixed-step mutation for all gameplay logic.

## Input Rules

- Use named input actions from `project.godot`.
- Avoid hardcoding keycodes inside gameplay scripts.

## Determinism Rules

- Any RNG used for gameplay must be seedable and reproducible.
- Avoid time-based nondeterministic branching in simulation code.

## Testing/Validation Rules

- For major systems, include deterministic validation scenarios.
- Keep migration notes when behavior ports from legacy Python references.
