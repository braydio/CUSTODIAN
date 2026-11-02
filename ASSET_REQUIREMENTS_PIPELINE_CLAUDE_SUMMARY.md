# Asset Requirements Pipeline Summary

## Changes

- Hardened registry validation for required fields, kebab-case IDs, declared lifecycle states, normalized duplicate targets, exact `state`/`scope` selection, `required_states` family scope, and section notes. Structural errors stop doctor before generated-view projection.
- Added live family-scope expansion and per-evaluation family-status caching. State and scope evidence now expose missing/satisfied states and staged-source status. `asset needs <id>` recommends `request` for missing unstaged source, `plan` for staged source, both when evidence is mixed, and no action for fulfilled requirements.
- Enabled declared `fulfilled` for non-V2 routes while retaining records and omitting them from the active generated view. Rejected ambiguous CLI mode combinations.
- Restored five lost section notes, corrected three generic combat effects from Operator to manual fulfillment, removed one-time Markdown migration code/test, corrected three active design references, and added production-requirements guidance to `custodian/AGENTS.md`.
- Added exactly the ten packet-authorized Asset V2 mappings. Root `REQUIRED_ASSETS.md` was regenerated from the registry.

## Measured state

- 115 requirements total: 113 active, 2 fulfilled.
- Routes: 13 Asset V2, 56 manual, 17 Operator, 18 Tiled, 8 audio, 3 review.
- Added mapping statuses: zone plates `fulfilled`; relay lamp `needed`; zone fixtures `partial`; authority inlay `needed`; ruin decal `needed`; Awakening FX `needed`; Opossum threat `needed`; Opossum reaction/friendship `needed`; hide-exit body/barrel `needed`; barrel hide-layer framing `needed`.

## Validation

- Requirement smoke, Asset CLI UX, Asset Pipeline V2 and V2.1, plan/status/ingest/replacement/transaction/backend smokes, Vaultwing contract (65 strips), and Baby Opossum contract (22 strips) passed.
- `asset needs --check` passed. `asset doctor` returned no errors and one existing warning: unregistered `operator` inbox containing 12 PNGs.
- Python compile checks and `git diff --check` passed.
- Closeout `run_validation.py --changed --max-tier unit --json`: passed 3/3 selected unit checks (`agent_workflow_contract`, `asset_pipeline_v2`, `asset_requirements`), zero failures, timeouts, or infrastructure errors. Green report: `/tmp/asset-requirements-pipeline-validation.json`.
- Moment Forge: not run — tooling, registry, and documentation changes only; no runtime or presentation behavior changed.

## Awkward bits and deferred work

- The first temporary smoke iteration had not written its completed/source-action fixtures into the temporary registry; the assertions exposed this and the fixture setup was corrected.
- An extra attempted validation path, `asset_pipeline_hardening_smoke.py`, does not exist. The actual shared test library ran through `asset_pipeline_v2_smoke.py`, and the packet's required focused smokes passed.
- Audio, Tiled, Operator, and review status remain declared and workflow-updated. No new art, families, adapters, or priority features were added.
