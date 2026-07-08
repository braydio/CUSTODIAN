# CUSTODIAN Idea Codex

`design/90_codex/` is a parking lot and triage system for ideas that should not be lost.

It is not active runtime truth, not a design-spec replacement, and not implementation authority. Active implementation specs remain in `design/01_systems/`, `design/02_features/`, `design/04_architecture/`, and other scoped design folders. Current live runtime state remains tracked in `custodian/docs/ai_context/CURRENT_STATE.md`.

## Use

1. Capture a new idea in one sentence in `02_backlog.md`.
2. Promote durable ideas into full cards using `templates/IDEA_CARD.md`.
3. Triage each card with status, category, priority, maturity, and cost.
4. Review periodically and move only the strongest ideas to `candidate`.
5. Graduate a card by creating or updating a real implementation spec under the active design tree, usually `design/02_features/` or `design/01_systems/`.
6. When runtime behavior is implemented, update `custodian/docs/ai_context/CURRENT_STATE.md`.

## Authority Boundary

- Codex cards can describe intent, tradeoffs, and possible futures.
- Codex cards must not override active implementation specs.
- Runtime code should not cite a codex card as authoritative behavior.
- A card becomes buildable only after it graduates into a real implementation spec.

## Status Values

- `seed` - captured, not judged
- `triaged` - reviewed and categorized
- `candidate` - worth designing soon
- `graduated` - moved to real implementation spec
- `deferred` - good idea, wrong time
- `cut` - intentionally rejected

## Priority Values

- `P0` - identity-defining
- `P1` - high value
- `P2` - useful later
- `P3` - polish
- `P4` - experiment only

## Maturity Values

- `vibe` - cool but vague
- `mechanic` - clear player effect
- `system` - clear implementation shape
- `spec-ready` - ready to become a real design doc

## Graduation Rules

To graduate, create or update an active implementation spec outside `90_codex/`. Use the current design structure, not this folder, as the implementation home. If a future `design/20_features/in_progress/` lane is created, graduated feature specs may target it; in the current tree, use the closest existing active folder such as `design/02_features/`, `design/01_systems/`, or `design/04_architecture/`.

Graduation should include:

- a clear implementation owner and runtime surface
- dependencies and deterministic simulation constraints
- acceptance checks and validation recipe
- updates to `custodian/docs/ai_context/CURRENT_STATE.md` only when implementation changes live runtime state

