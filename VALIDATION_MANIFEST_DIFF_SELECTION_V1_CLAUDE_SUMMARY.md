# Validation Manifest Diff Selection V1

## Result

Changed-file validation now treats `validation_manifest.json` as test-selection metadata rather than an ordinary test-owned source file. It compares the current manifest against the unique merge-base version and selects only added or modified test definitions, the runner's manifest self-checks, and tests matched by other changed source paths. Coverage accounting still includes the manifest path.

Removed definitions, duplicate or malformed JSON, duplicate IDs, unavailable/ambiguous merge bases, and global manifest configuration changes fail closed with a configuration error. Tier execution and failure propagation are unchanged.

## Verification

- Correction branch started from `origin/main@0c162bdd`.
- Full changed-file validation: passed, 5 selected / 5 passed / 0 failed / 0 skipped; coverage complete.
- Selected: `godot_import_lfs_preflight`, `godot_project_lock`, `validation_failure_triage_unit`, `validation_manifest_diff_selection`, `validation_runner`.
- `npa_showcase_existing_enemy` was not selected.
- Regression cases cover an Alpine-only definition addition, a modified NPA definition, an NPA-owned source change, removed/duplicate definitions, malformed and duplicate-key JSON, global config changes, and preserved failed-test status.
- Independent clean `origin/main@0c162bdd` reproduction remains recorded at `/home/braydenchaffee/Projects/.custodian-staging/alpine-validation/npa-origin-main-0c162bd.json`; the NPA test fails to parse its GDScript due uninferred local types (`chain`, `grunt`, `carrier`, `lethal`, `corpse_loot`). No NPA implementation or expectation was changed.
- The original Alpine red report remains at `/home/braydenchaffee/Projects/.custodian-staging/alpine-validation/changed-origin-main.json`.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: manifest ownership previously selected every test that declared the manifest as an owner
- Root cause / contributing factors: selection treated metadata-file ownership as source impact
- Prevention / pipeline improvement: compare manifest definitions by stable test ID and retain fail-closed behavior for unsafe diffs
- Tooling / docs drift discovered: none
- Follow-up: procgen-alpine-cliff-presentation-v1
- What worked: focused changed-file report retained complete coverage while excluding unrelated NPA validation

## Next Handoff
- Next workstream: procgen-alpine-cliff-presentation-v1
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: n/a
- Refresh reason: none
- Next action: land this selector correction, then rerun Alpine changed-file validation and complete its existing lifecycle if green
- Blockers or open questions: none for this correction; Alpine closeout remains pending its own current-main validation and lifecycle finish
