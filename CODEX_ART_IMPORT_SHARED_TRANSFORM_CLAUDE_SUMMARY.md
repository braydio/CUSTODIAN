# Codex Art Import Shared Transform — Implementation Summary

Workstream: `codex-art-import-shared-transform`

Implemented a versioned canonical JSON source-sheet plan and a read-only render API under `custodian/tools/assets/sprite_import/`. The contract binds source bytes and SHA-256 to explicit semantic identity, cell geometry, layout, target dimensions, alpha policy, resampler, and anchor. The plan records deterministic row-major frame order, shared alpha union, uniform scale and placement, expected strip dimensions, zero-initialized frame registrations, contract provenance, and its own digest. Rendering verifies the plan against the same source and contract, then reuses the converter’s existing shared geometry, preparation, resize, and reassembly routines.

Added Asset V2 family/state and accepted Operator profile adapters. Added shared converter helpers and safety checks for unsupported single-image replay plans, empty alpha, source/output identity, input/preparation allocation limits, and exact sheet preparation budgets. Added `shared_import_contract_for_session` as a narrow Operator contract adapter; production remains on the established `pixelart --choose 1` pathway.

Golden geometry and replay checks passed: 8 × 512px cells to a 1024 × 128 strip, 3 × 2 cells of 256px to a 768 × 128 strip, and a 128 × 160 prop. Soft illustrated alpha retains intermediate values while pixel-crisp output remains binary. Ambiguous dimensions, invalid contracts, digest mismatch, empty input, allocation overflow, forced source overwrite, and ignored single-image replay plans fail closed.

## Validation

- `python3 custodian/tools/validation/sprite_import_shared_transform_smoke.py` — passed.
- `python3 custodian/tools/validation/operator_art_source_smoke.py` — passed.
- `python3 custodian/tools/validation/operator_art_registration_profile_smoke.py` — passed.
- `python3 custodian/tools/validation/pixelart_colors_smoke.py` — passed.
- `python3 custodian/tools/validation/asset_pipeline_plan_smoke.py` — passed.
- `python3 custodian/tools/validation/run_validation.py --test sprite_import_shared_transform --json` — passed with a green manifest report.
- `python3 custodian/tools/validation/run_validation.py --changed --json` — infrastructure failure: Godot import/reimport exited `-11` at reimport before tests ran. This remains an outstanding validation rerun after the importer environment is healthy.
- Python compilation checks passed for the new package, converter, Operator adapter, and focused smoke.

No production art, runtime asset, or publishing behavior changed. The main awkward part was repository-path correction in the new smoke plus a Godot importer crash during the broad changed-file pass; neither affected the focused Python checks.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: changed-file validation stopped at Godot import/reimport exit -11 before test execution.
- Root cause / contributing factors: importer process crashed at 99% reimport without a code-level diagnostic.
- Prevention / pipeline improvement: rerun changed-file validation after the importer environment is healthy; focused registered Python coverage remains green.
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: deterministic focused geometry checks and existing Operator/Asset V2 smokes passed.

## Next Handoff
- Next workstream: review-codex-art-import-shared-transform
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc3bfd-cf88-83ea-9156-be4e5c2851c0
- Refresh reason: none
- Next action: complete the fresh-context paired review after implementation lands; then dispatch `codex-art-import-registration` when its dependency is complete.
- Blockers or open questions: changed-file validation needs a rerun because Godot import/reimport crashed with exit -11.
