# Operator 2.5D Workbench Cockpit Foundation (WB25-1)

## Result

Implemented the first target-driven 2.5D animation workbench slice. Authoring
identity now includes `art_generation` while semantic/runtime identity remains
stable. Legacy canonical source paths are byte-for-byte unchanged, and 2.5D
source and workspace paths use a separate `operator_2_5d_128` namespace.

The implementation plan is backward-readable as v2, preserves legacy rank,
priority, and state, repairs stale generic action groups, and seeds all 69
production-reachable targets: one accepted authored family and 68 missing
counterparts (544 baseline direction strips). A single projection distinguishes
canonical, partial, fallback, projected, missing, stale-reference, and workflow
states. It supplies both the generation-separated browser tree and the
2.5D action-by-direction matrix. Matrix selection reaches the same authoring
identity as tree selection.

Production runtime selectors/resources and New Animation behavior were not
changed. Import orchestration, art mutation, QA automation, and production
cutover remain deferred to later packets.

## Evidence

- `operator_animation_targets_smoke.py` passed: 69-family projection, accepted
  source/hash state, generation identity/path separation, canonical/fallback/
  projected negatives, and stale-reference detection.
- `operator_animation_plan_smoke.py` passed: v1 read compatibility, v2 counts,
  first canonical row, and legacy state preservation.
- `operator_asset_schema_smoke.py` passed: exact legacy path compatibility and
  distinct 2.5D source path.
- Textual-enabled `operator_workbench_ui_smoke.py` passed, including the matrix
  cell event and shared tree/matrix selection identity.
- `run_validation.py --changed --json` passed: 19/19 selected checks, no
  failures, no uncovered changed files.
- Python compile checks and `git diff --check` passed.

The first changed-files validation attempt returned exit 6 because the new
projector/schema files lacked validation-manifest test ownership, although all
selected checks passed. Added target and schema test registrations and reran the
gate successfully. Godot validation generated only `.import` sidecars for the
canonical reference images; those disposable sidecars were removed.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: Initial changed-files validation found missing test ownership for new source files.
- Root cause / contributing factors: The implementation added focused tests before registering their owners with the repository validation runner.
- Prevention / pipeline improvement: Added runner entries and ownership mappings; the complete-coverage rerun passed.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: The target projection and matrix/tree selection checks provide direct negative and integration evidence without renderer captures.

## Next Handoff
- Next workstream: review-operator-2-5d-workbench-cockpit-foundation
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: claim the paired post-land review in a fresh reviewer context and verify the archived implementation contract.
- Blockers or open questions: none
