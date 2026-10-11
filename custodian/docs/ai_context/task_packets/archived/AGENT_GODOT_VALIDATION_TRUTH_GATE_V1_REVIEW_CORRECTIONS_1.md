# AGENT GODOT VALIDATION TRUTH GATE V1 — REVIEW CORRECTIONS 1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-godot-validation-truth-gate-v1-review-corrections-1`
- Kind: `correction`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `validation-infrastructure, asset-pipeline`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-godot-validation-truth-gate-v1-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `Close confirmed R0-01 fail-open in the import metadata gate`
- Findings addressed: `R0-01`
- Reviewed main: `455392871`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Repeat exact Authoring chat URL in correction/review summaries and Next Handoff.
- Goal: Close R0-01 so a malformed tracked PNG import sidecar cannot evade preflight when its source metadata is missing.
- Completion boundary: Correct reference association and required metadata validation in the existing preflight, with focused regression coverage; no importer/runtime changes.
- Current measured state: Fresh review reproduced `preflight_detail() == None` for a tracked `assets/bad.png.import` with `valid=false`, empty destinations, no `source_file`/UID, and a direct scene reference to `res://assets/bad.png`.
- Evidence: Archived implementation packet `AGENT_GODOT_VALIDATION_TRUTH_GATE_V1.md`, its `Independent Review` R0-01 receipt, and `REVIEW_AGENT_GODOT_VALIDATION_TRUTH_GATE_V1_CLAUDE_SUMMARY.md`.
- Task-specific authority: Existing `godot_import_preflight.py`, its focused smoke, and the original archived implementation packet.
- Work surface: `custodian/tools/pipelines/godot_import_preflight.py` and `custodian/tools/validation/godot_import_preflight_smoke.py`; narrowly adjust owner entries only if needed.
- Change: Associate tracked `.png.import` candidates with the PNG implied by their tracked sidecar path even when `source_file` and UID are absent. Treat absent required source/remap metadata as malformed. Add a direct scene-path negative fixture for the missing-source/UID case.
- Required correction: Make R0-01's tracked sidecar fail preflight when its scene references the PNG path inferred from the `.png.import` filename, even with absent `source_file` and UID fields. Validate required source metadata and preserve current valid, invalid, unreferenced, untracked, direct-path, and UID cases.
- Preserve: Existing direct path and UID matching, 15 invalid-sidecar detection, ignored unreferenced/untracked sidecars, local-cache-only LFS policy, exact runner rollback exceptions, and no Godot runtime behavior changes.
- Non-goals: No asset auto-repair, broad import rewrite, warning-registry relaxation, new importer, or changes to Godot gameplay/runtime code.
- Acceptance: 1) The R0-01 fixture blocks import; 2) valid referenced sidecars still pass; 3) unreferenced malformed and untracked sidecars retain current behavior; 4) all existing import-preflight and runner negative controls pass; 5) registered import-truth resources load and the changed-file sweep is green.
- Validation: Run `godot_import_preflight_smoke.py` and `validation_runner_smoke.py`; run `run_validation.py --tag import_truth --json`; run `run_validation.py --changed --base origin/main --json`, `check_ai_context.py --json`, packet index/pairing, and `git diff --check`.
- Deferred: Broader sidecar format auditing and automatic metadata repair.

- Task overrides: `none`

## Completion Truth
- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: The malformed tracked sidecar with no source_file or UID is associated with the PNG implied by its .png.import path and missing source metadata is reported. The direct scene-path regression fixture blocks preflight; valid, invalid, unreferenced, untracked, direct-path, and UID controls pass. Focused smokes pass; import_truth passes 3/3 on retry; changed-file sweep passes with complete coverage.

## Execution Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: low
- What went wrong: First import_truth run emitted a TLS handshake error and two WAV size warnings; retry passed. The first finish attempt also caught a missing machine-readable Completion Truth schema.
- Root cause / contributing factors: Transient Godot TLS/import infrastructure failure; the completion receipt was initially written as prose rather than the required schema fields.
- Prevention / pipeline improvement: none
- Tooling / docs drift discovered: none
- Follow-up: none
- What worked: Focused fixture reproduced and closed the review finding.

## Next Handoff
- Next workstream: review-agent-godot-validation-truth-gate-v1-review-corrections-1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Refresh reason: none
- Next action: After correction lands and archives, run the paired fresh-context correction review.
- Blockers or open questions: none

## Independent Review
- Status: passed
- Review workstream: review-agent-godot-validation-truth-gate-v1-review-corrections-1
- Reviewed on main: 6b5f3a83
- Review modes: code, architecture, workflow
- Reviewer provenance: same-agent-fresh-context
- Findings: R0-01 fixed; no new R1-NN findings.
- Evidence: Exact metadata-free sidecar fixture blocks preflight; valid, invalid, unreferenced, untracked, direct-path, UID, missing-path, and missing-destination controls pass. Focused smokes pass; import_truth passes 3/3; changed-file and review-pairing sweeps pass.
