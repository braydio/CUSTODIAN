# Operator 2.5D Workbench Ingress (WB25-2)

Implemented the guided target-bound NEW/IMPORT ingress in `operator-2-5d-workbench-ingress`. The implementation extends existing Workbench and SourceArtService authorities and preserves the hard boundary against 2.5D runtime publication.

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb

## Delivered

- Added generation-aware NEW creation while keeping `legacy_96` as the default and retaining legacy source/workspace paths. 2.5D creation uses its own canonical source path/workspace; a legacy counterpart is not treated as a same-generation collision.
- Added backward-readable Source Session v2 target binding, including semantic target and accepted profile/reference authority, with donor/source provenance. Existing v1 sessions retain their prior behavior.
- Parameterized SourceArtService production command/proof dimensions from the session. Generation-scoped handoff is idempotent and checks the matching authoring destination.
- Added `Operator2DIngress` with exact projected-target checks, explicit eight-direction maps, resumable ignored package manifests, stale-source/authority refusal, import processing, handoff, and editable Workbench opening. UI now offers direct NEW and one-file/eight-direction IMPORT.
- Added fail-closed 2.5D publication guards before legacy publish/reconciliation mutation. Runtime assets/resources/selectors are not changed by this workstream.
- Added focused ingress smoke coverage and updated the validation manifest; repaired a stale implementation-plan fixture in the existing workbench smoke.

## Registration constraint discovered

The accepted `operator_2_5d_128` profile has an empty `scale_segments` list, so the legacy 96px normalization path could not safely be reused. For the accepted 128×128 cell size, normalization now preserves exact source pixels with an identity transform and records that semantic root is not asserted. Other cell sizes fail closed rather than deriving registration from alpha bounds. This keeps the profile's no-inferred-root rule intact.

## Validation

- `operator_animation_targets_smoke.py`: passed.
- `operator_asset_schema_smoke.py`: passed.
- `operator_art_source_smoke.py`: passed.
- `operator_art_registration_profile_smoke.py`: passed.
- `operator_animation_workbench_smoke.py`: passed.
- Textual-enabled `operator_workbench_ui_smoke.py`: passed on retry after one timer teardown race on the initial run.
- `operator_2_5d_ingress_smoke.py`: passed end-to-end.
- `run_validation.py --changed --json`: 29 selected, 29 passed, 0 failed/timeouts/infrastructure errors; coverage complete. Report: `/tmp/wb25-2-changed-validation-final.json`.
- `python3 -m compileall -q custodian/tools/operator custodian/tools/validation`: passed.
- `git diff --check`: passed.
- Graph change analysis covered 14 changed implementation/test files; it flagged 36 test gaps in symbol-level mapping, while the focused ingress and existing workbench/source/UI smokes exercise the user-facing flows and acceptance boundaries.

## Friction and limits

The first final sweep waited on an already-running serialized Godot sweep. I stopped only the competing invocation and let the active sweep finish; that sweep passed. The UI teardown race did not reproduce on retry. Generated Godot `.import` sidecars and pilot report folders were removed after validation. No source/runtime art was promoted, and subjective visual approval was outside this packet.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The 2.5D profile's empty scale map exposed a hard-coded 96px normalization assumption; one UI smoke attempt hit a transient timer teardown race; a competing validation attempt waited on the repository's Godot lock.
- Root cause / contributing factors: Legacy normalization assumed a scale segment; the UI smoke uses asynchronous timer teardown; broad validation serializes Godot project access.
- Prevention / pipeline improvement: Added exact-cell identity normalization for accepted 128px inputs and fail-closed behavior otherwise; the final changed sweep ran serially and passed.
- Tooling / docs drift discovered: Packet should make the empty 2.5D `scale_segments` constraint explicit for future source normalization work.
- Follow-up: review-operator-2-5d-workbench-ingress
- What worked: Deterministic ingress smoke proved target binding, resume, idempotent staging, and no runtime mutation.

## Next Handoff
- Next workstream: review-operator-2-5d-workbench-ingress
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac698a4-ca68-83ea-bc0e-3b8a52e4e0fb
- Refresh reason: none
- Next action: Claim the paired post-land review in a fresh reviewer context.
- Blockers or open questions: none
