# Startup World Entry Spine V1 — Codex Summary

## Outcome

- Added `game/app/boot/runtime_entrypoint.tscn` and a small runtime router; `project.godot` now enters through this App/Boot scene.
- No-argument startup routes to Awakening and does not call `WorldContractBootstrap`.
- Added fixed development targets for Twin Solaria's existing playtest wrapper and the existing Contract sandbox `game.tscn`.
- Contract startup calls the persistent bootstrap once, before the scene switch, and passes through an optional nonzero integer seed. It does not wait for generation.
- Unknown modes and malformed, duplicate, or inapplicable seeds warn and fall back to Awakening. Arbitrary scene paths are not accepted.
- Updated App/Boot, architecture, current-state, context, file-index, design, and validation documentation. Added a manifest-owned startup integration smoke and updated existing boot assertions.
- Regenerated the tracked Awakening connector plate `.import` metadata from its locally cached LFS source. The old record had `valid=false` and stopped the production default scene from loading. No LFS fetch was performed.

## Validation

- `startup_world_entry` — passed: real Awakening, Twin, invalid-mode, and Contract scene routing; default generation count zero; Twin Hub level/Crown Causeway metadata; one seeded generation still in flight after `game.tscn` loads.
- `world_contract_prewarm` — passed: ready map reuse through `WorldContractProxy` and `ContractWorldLoader`, with one generation.
- `awakening_first_return` — passed.
- `twin_solaria_runtime` — passed.
- `run_validation.py --changed --json` — passed all 13 selected tests with complete ownership coverage.
- The first startup smoke draft completed a real procgen generation and failed against the incomplete fake world's required ingress; one run timed out while that generation finished. The final smoke uses a pending fake generator for the in-flight scene-boundary check and leaves ready-map consumption to the dedicated prewarm smoke.
- The changed-file sweep selected two Moment-tier validations because the corrected connector import metadata is their owner. Both passed; their generated timestamped reports were classified as disposable and removed. No separate Moment Forge evidence/full capture was needed.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: the first smoke draft accidentally drove full production-world generation and an initial import-cache miss obscured the Awakening scene load; the changed-file sweep also selected two Moment-tier validations through the connector metadata owner.
- Root cause / contributing factors: a completed fake contract invokes the full production loader; the worktree began with pointer-only LFS files and a checked-in connector import record marked invalid; manifest ownership correctly connected that import record to existing Awakening moment checks.
- Prevention / pipeline improvement: the smoke now holds a fake generation in flight while checking scene routing, with ready-contract reuse covered separately; local cached LFS checkout and one focused asset reimport enabled runtime validation.
- Tooling / docs drift discovered: invalid connector `.import` metadata; corrected in-scope and included with the startup target.
- Follow-up: none
- What worked: focused, serial startup and scene regressions kept the proof bounded while covering all three entry modes.
