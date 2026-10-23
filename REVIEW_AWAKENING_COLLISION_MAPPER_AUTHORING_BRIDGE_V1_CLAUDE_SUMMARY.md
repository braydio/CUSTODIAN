# Awakening Collision Mapper Authoring Bridge V1 — Independent Review

## Findings

- **R0-01 — Blocking: draft reopen does not restore authoring metadata.**
  `awakening_first_return_collision_mapper.gd::_load_saved_draft` reconstructs
  vertices and several proposal fields, but ignores the saved `snap_px` and
  `source_art` resource/transform/pixel coordinates. Reopening a draft made at
  1px snap therefore returns to the scene default, and saved source-art
  provenance is discarded and recalculated on the next save. This violates the
  required lossless round trip and A3's stable source-art transform evidence.
  The current bridge smoke checks serialized JSON readback, not an actual
  mapper save/reopen for the canonical Z01 and Z07 samples.
- **R0-02 — Blocking: required artist export/capture controls are absent.**
  The Awakening mapper and inherited mapper contain no clipboard exact-vertex
  export or annotated PNG/JSON capture operation. Those are explicit parts of
  the archived implementation contract's draft workflow, so the author cannot
  hand off the requested annotated geometry evidence through the mapper.

These defects prevent a PASS receipt and user collision authoring acceptance.
No reviewed implementation or runtime file was edited. The review packet stays
active and unarchived for bounded correction and re-review.

## Review Identity

- Review workstream: `review-awakening-collision-mapper-authoring-bridge-v1`
- Review target workstream: `awakening-collision-mapper-authoring-bridge-v1`
- Reviewer context/provenance: `fresh` / `different-agent`
- Reviewed main: `bb5dedd62fd0edaf09cab811ec0d585b4f76afdf`
- Reviewed implementation commit: `4bdb31b81e2580e48e05eb84909ec7d90eeb44f5`
- Authoring chat: not-recorded

## Validation Evidence

- PASS: `awakening_collision_mapper_bridge` through `run_validation.py` (1/1).
- PASS: direct headless `awakening_first_return_smoke.gd`.
- PASS: direct headless `awakening_first_return_geometry_smoke.gd`.
- PASS: direct headless `authored_level_mapper_framework_smoke.gd`.
- PASS: direct headless `level_collision_poi_mapper_smoke.gd`.
- PASS: direct headless `sundered_keep_mapper_smoke.gd`.
- PASS: `check_ai_context.py --json` and `task_packet_index.py`.
- PASS: scoped `git diff --check` for Awakening mapper and Sundered smoke files.
- PASS: `awakening_layout.gd` is byte-identical at the pinned implementation
  and reviewed main (Git blob `ac1c5782e4dbceda59b7bf8f6ddba2e0b2c95bbb`).
- BLOCKED: rendered gate-pylon and 04→05 crop inspection was not available in
  this headless restricted checkout; the headless geometry fixture passed.
- BLOCKED: aggregate `run_validation.py` selection and changed-file coverage;
  its import preflight reports Godot TCP listener creation errors in this
  sandbox. Individual required smoke scripts were run directly and passed.
- BLOCKED: `validate_review_pairing.py` attempts `git fetch --prune origin`,
  which this restricted review assignment prohibits; Git also reports the
  shared worktree metadata is read-only.
- The broad historical diff check also reports pre-existing trailing
  whitespace in unrelated files; the scoped changed-file check above is clean.

Structured validation evidence: `/home/braydenchaffee/Projects/CUSTODIAN/.git/custodian-review-runs/review-awakening-collision-mapper-authoring-bridge-v1/20261016T095141Z-bf971dc50521/validation.json`.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: partial
- Friction severity: medium
- What went wrong: aggregate import and pairing validators require facilities
  unavailable under this restricted reviewer checkout.
- Root cause / contributing factors: the Godot import preflight cannot create
  listener sockets; the pairing validator performs a prohibited fetch.
- Prevention / pipeline improvement: provide a no-fetch pairing validation
  mode and a headless import preflight that avoids optional listener startup.
- Tooling / docs drift discovered: the bridge smoke does not exercise mapper
  reopen metadata or the two author handoff export paths.
- Follow-up: manual-follow-up

## Next Handoff

- Next workstream: none
- Next packet state: human-required
- Refresh owner: chatgpt-user
- ChatGPT/user planning refresh required: yes
- Authoring chat: not-recorded
- Refresh reason: two blocking findings require bounded implementation correction
  and fresh paired review; aggregate validation is also blocked by checkout limits.
- Next action: create/authorize the bounded correction workstream from these findings, then
  rerun the paired review. This review packet remains active and recoverable.
- Blockers or open questions: none
