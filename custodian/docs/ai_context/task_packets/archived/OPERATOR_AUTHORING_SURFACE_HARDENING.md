# Operator Authoring Surface Hardening

- Workstream: `operator-authoring-surface-hardening`
- Status: `complete`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `operator-authoring-tooling`
- Goal: Bring the active Operator authoring documentation and focused ingest wrapper into exact alignment with the current Workbench V5 / Operator V2 source-to-runtime authority, remove broken legacy instructions, expose safe targeted runtime-sync controls, and add a cheap regression guard so this drift does not return.
- Current measured state: `main@49649b35c23a558a1188ec4f0b375f92218317b2` uses WORKBENCH `Ctrl+R` and five UI modes; `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md` still documents `Shift+R` and modes 1-4. The cheatsheet and active `custodian/content/sprites/_pipeline/README.md` still direct users to deleted `custodian/tools/pipelines/build_operator_modular_runtime.py` and the retired `operator/new_operator/modular/` → `runtime/modules/new_operator/` route. Live Operator V2 authority is `content/sprites/operator/source/animations/` → `content/sprites/operator/runtime/animations/` through `sync_operator_runtime_assets.py`. `operator_ingest.sh` already wraps that backend but does not expose its useful `--profile` or `--strict` controls. The previously reported `melee_1h/locomotion/run_01/s` manifest gap is no longer present on current main and is not part of this task.
- Task-specific authority: `design/02_features/animation/OPERATOR_ANIMATION_WORKBENCH.md`; `design/04_architecture/SPRITE_PIPELINE_SYSTEM.md`; `custodian/docs/ai_context/FILE_INDEX.md`; `custodian/docs/ai_context/VALIDATION_RECIPES.md`; `custodian/tools/operator/operator_ingest.sh`; `custodian/tools/pipelines/sync_operator_runtime_assets.py`.
- Change: Correct the two active Operator pipeline/how-to docs to current Workbench V5 shortcuts, modes, paths, and entrypoints. Add explicit `--profile <profile>` and `--strict` options to `operator_ingest.sh` and forward them consistently to every `sync_operator_runtime_assets.py` invocation where they apply, without changing the wrapper's dry-run default. Add a focused active-document/tooling contract smoke that rejects reintroduction of the deleted builder/current-authority legacy paths and detects Workbench shortcut/mode drift; register it in `validation_manifest.json`. Update `CURRENT_STATE.md` or `FILE_INDEX.md` only if the implemented contract makes their current statements stale.
- Preserve: Workbench publish remains the only authority that replaces canonical Operator source from a disposable workbench. Canonical source/runtime layout remains `source/animations` and `runtime/animations`. Existing `operator_ingest.sh` flags and dry-run-by-default behavior remain valid. Historical/archived packets, reports, legacy assets, and migration evidence remain historical evidence and are not rewritten merely because they contain old names. No Asset V2 or gameplay authority is moved.
- Non-goals: Do not restyle or publish `unarmed/defense/block_hit_01` art in this task. Do not change animation timing, frame contracts, gameplay state selection, hit windows, or weapon ownership. Do not introduce a new Operator pipeline or perform a broad content-tree migration. Do not take ownership of generic workstream finish/archive defects already tracked by `WORKSTREAM_FINISH_LANDED_CLOSEOUT_HARDENING.md`.
- Acceptance: Active Operator authoring docs no longer recommend the deleted builder or retired modular source/runtime trees as current workflow; the cheatsheet documents modes 1-5 and WORKBENCH `Ctrl+R`; `operator_ingest.sh --help` documents `--profile` and `--strict`, while no-argument behavior remains dry-run; a focused wrapper test proves `--profile unarmed` and `--strict` are forwarded to the runtime sync calls without broadening to unrelated profiles; the active-doc/tooling contract smoke fails on the known stale strings/shortcut regression and passes after remediation; relevant Operator Workbench/pipeline smokes pass; one `run_validation.py --changed --json` closeout run is performed after focused validation; active-doc drift is rechecked and no conflicting current Operator authoring route remains. Moment Forge is not required because this slice changes tooling/docs only and no runtime presentation behavior.
- Task overrides: `none`
- Deferred: The deeper-orange `unarmed/defense/block_hit_01` art conversion remains a separate animation-production task. Generic workstream closeout/packet archival hardening remains with its existing P0 workstream. Installing optional Textual dependencies globally is not part of this slice.

## Ownership And Timing

- Owner: Claude
- Agent/session: Claude Sonnet 5, `agent/operator-authoring-surface-hardening`
- Created: 2026-09-28
- Last updated: 2026-09-28

## Completion Notes

- Corrected `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md` and
  `custodian/content/sprites/_pipeline/README.md` to live Workbench V5 modes
  `1`–`5`, the `Ctrl+R` canvas-resize review flow, and the live
  `operator/source/animations/` → `operator/runtime/animations/` sync route,
  removing the retired `Shift+R`, `1`–`4`, `build_operator_modular_runtime.py`,
  and `update_operator_curated_resources.gd` references.
- Added `--profile`/`--strict` to `operator_ingest.sh`, forwarded to every
  `sync_operator_runtime_assets.py` call; dry-run default and existing flags
  unchanged.
- Added and registered `operator_authoring_surface_contract_smoke.py` (derives
  live modes/shortcut from `app.py`, fails on doc drift or legacy-path reintroduction)
  and `operator_ingest_wrapper_smoke.py` (proves `--profile`/`--strict` forwarding
  and real scoping) in `validation_manifest.json`.
- Full acceptance criteria met; see
  `OPERATOR_AUTHORING_SURFACE_HARDENING_CLAUDE_SUMMARY.md` at repo root for
  validation evidence and deferred/awkward notes.

## Work Surface

- Files/systems to change:
  - `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`
  - `custodian/content/sprites/_pipeline/README.md`
  - `custodian/tools/operator/operator_ingest.sh`
  - focused validation under `custodian/tools/validation/`
  - `custodian/tools/validation/validation_manifest.json`
  - consequence-driven AI-context docs only if their current statements become stale
- Related consumers or tests:
  - `custodian/tools/pipelines/sync_operator_runtime_assets.py`
  - `custodian/tools/validation/operator_animation_workbench_smoke.py`
  - `custodian/tools/validation/operator_workbench_ui_smoke.py`
  - `custodian/tools/validation/operator_modular_pipeline_smoke.py`
  - `custodian/docs/ai_context/VALIDATION_RECIPES.md`

## Plan

1. Reproduce the documentation/tooling mismatches against live main and establish the smallest active-doc string/command contract that should remain true.
2. Correct active documentation, add wrapper parity for `--profile` and `--strict`, and add focused regression coverage without changing canonical animation or gameplay behavior.
3. Run focused tests first, then one changed-file closeout sweep; perform a final active-document drift scan and update only docs made stale by the implementation.

## Handoff

- Next action: Claim `operator-authoring-surface-hardening`, inspect the live authority files above, and baseline `operator_ingest.sh --help` plus the known stale active-doc references before editing.
- Best starting files: `custodian/tools/operator/operator_ingest.sh`, `custodian/tools/pipelines/sync_operator_runtime_assets.py`, `custodian/docs/SPRITE_PIPELINE_CHEATSHEET.md`, and `custodian/content/sprites/_pipeline/README.md`.
- Blockers or open questions: none.
