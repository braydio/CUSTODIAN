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

## Runtime Fields

Cards with live support use these informational fields:

- `Runtime status:` — whether a runtime slice is live
- `Runtime path:` — the live implementation entrypoint
- `Graduated to:` — the active implementation spec that owns build truth

These fields do not grant the card implementation authority. A graduated card remains an idea-history record and pointer; use its active design spec and `custodian/docs/ai_context/CURRENT_STATE.md` for build truth.

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

To graduate, create or update an active implementation spec outside `90_codex/`. Use the current design structure, not this folder, as the implementation home. Use the closest existing active folder such as `design/02_features/`, `design/01_systems/`, or `design/04_architecture/`. (Note: `design/20_features/` was consolidated into `design/02_features/`.)

Graduation should include:

- a clear implementation owner and runtime surface
- dependencies and deterministic simulation constraints
- acceptance checks and validation recipe
- `Status: graduated`, `Graduated to:`, and any live `Runtime status:` / `Runtime path:` metadata on the original card
- updates to `custodian/docs/ai_context/CURRENT_STATE.md` only when implementation changes live runtime state

## Governance

The Design Codex is idea inventory, not active implementation authority.

Before using a codex card for implementation, graduate it into the active design system under `design/02_features/`, `design/04_architecture/`, or another appropriate active design location.

Tracking lives in:

- `design/90_codex/TRACKER.md`

Validation:

```bash
python tools/validate_design_codex.py
```

Optional local pre-commit hook:

```bash
bash tools/install_git_hooks.sh
```

The hook validates codex structure only when codex files or codex validation tooling are staged.

Validation checks:

* canonical cards are listed in `00_index.md`
* indexed card paths exist
* required metadata fields exist
* graduated/runtime-backed cards point to active specs or runtime paths
* package-residue folders are reported
