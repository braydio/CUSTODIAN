# AGENT GODOT VALIDATION TRUTH GATE V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `agent-godot-validation-truth-gate-v1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `none`
- Locks: `validation-infrastructure, asset-pipeline`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-agent-godot-validation-truth-gate-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `Import and smoke results require independent negative-control review`
- Reviewed main: `4b5ba4c4f88f25cbde281ca6f148da58cd5648b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1`
- Visual review: `none`
- Summary backlink: Repeat exact Authoring chat URL in implementation/review/correction/recovery/closeout summary and Next Handoff.
- Goal: Reject false-green Godot smoke results and invalid imported runtime resource metadata while preserving narrowly authored expected rollback errors.
- Completion boundary: Extend existing LFS/import preflight, runner fatal-diagnostic handling and known warning registry with focused resource/scene negative controls; no second importer or resource authority.
- Current measured state: Vaultwing asset repair restored 15 tracked .png.import sidecars whose remap fields were missing and valid=false; a generated-region smoke printed PASS despite resource/type errors. run_validation.py already classifies fatal stderr, and known_headless_warnings.json includes expected rollback patterns.
- Evidence: custodian/tools/pipelines/godot_import_preflight.py; custodian/tools/validation/run_validation.py; known_headless_warnings.json; VAULTWING_IMPORT_METADATA_REPAIR_CLAUDE_SUMMARY.md; REVIEW_BRIDGED_FALLS_GENERATED_REGION_LIFECYCLE_CLAUDE_SUMMARY.md.
- Task-specific authority: Existing Godot import preflight, run_validation.py, validation manifest and Asset Pipeline V2 source authority.
- Work surface: Narrow edits to existing godot_import_preflight.py and run_validation.py, warning registry and focused unit/resource smoke fixtures; update validation manifest owners.
- Change: Before import, detect checked-out LFS pointer dependencies and tracked referenced .png.import sidecars with valid=false or missing required remap destination. After import, prove representative registered resources/scenes actually load; import process exit 0 is insufficient. Never allow a printed PASS sentinel to trump fatal parse/type/missing-resource diagnostics. Preserve exact test-owned expected rollback patterns and require near-miss negative tests; do not broaden global warning exceptions.
- Preserve: Local-cache-only LFS hydration, no implicit network fetch; writer lock, isolated Godot imports, real-alpha Asset V2 files, existing legit rollback tests and docs-only economy.
- Non-goals: No asset auto-repair, bulk .import restoration, new Godot importer, unbounded project import or game/runtime behavior changes.
- Acceptance: 1) Fixture for 15 invalid Vaultwing sidecars fails; 2) PASS text plus type/scene/resource parse errors fails; 3) missing GDExtension fails; 4) precisely expected rollback errors pass but near-match errors fail; 5) clean imported runtime resources prove actual load; 6) root/other worktrees remain byte-identical.
- Validation: Run focused import_preflight and runner negative unit fixtures; after LFS preflight/import, run existing registered actor_relationship_contract and Vaultwing resource checks plus representative generated-region smoke; run_validation.py --changed --base origin/main --json; check_ai_context.py --json, pairing/index and git diff --check.
- Deferred: Automatic asset metadata mutation, full asset census and new scene import authority.

- Task overrides: `none`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: yes
- Completion boundary satisfied: yes
- Acceptance satisfied: yes
- Evidence: Preflight fixture rejected 15 referenced invalid sidecars, missing remap destinations/paths, and ignored unreferenced/untracked broken files. Runner negative controls rejected PASS-plus-parse/resource/GDExtension errors and exit-zero import diagnostics; exact test-owned rollback lines passed, wrong-owner and near-match lines failed. One import-gated `--tag import_truth` run loaded actor relationship, Vaultwing runtime, and generated-region resources: 3/3 passed. Final changed-file sweep: 31/31 passed, complete coverage, no skips. AI-context checks reported zero findings; packet index and pairing passed; no tracked `.png.import` files changed in the claimed, root, or other worktrees.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: The first import-gated run correctly failed because generic fatal-error precedence rejected the generated-region smoke's registered shutdown resource-leak line. Existing expected rollback patterns were also unscoped and substring-matched.
- Root cause / contributing factors: Fatal classification did not distinguish hard parse/load errors from the deliberately registered shutdown diagnostic; expected rollback patterns were global and not exact-line anchored.
- Prevention / pipeline improvement: Keep parse/script/resource/GDExtension diagnostics fatal; bind expected rollback patterns to manifest test IDs and anchor them to full lines. Add positive, wrong-owner, near-match, and PASS-sentinel negative controls.
- Tooling / docs drift discovered: none
- Follow-up: `fixed-in-scope`
- What worked: A single import-gated tag ran actual scene/resource smokes after preflight/import, and the final changed-file sweep covered all changed runtime/tooling owners.

## Next Handoff

- Next workstream: `review-agent-godot-validation-truth-gate-v1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Refresh reason: `none`
- Next action: Land and archive this implementation, then run its fresh-context paired review.
- Blockers or open questions: none

## Independent Review

- Status: `findings`
- Review workstream: `review-agent-godot-validation-truth-gate-v1`
- Reviewed on main: `455392871`
- Reviewed implementation commit: `0adbe6265`
- Reviewer context: `fresh`
- Reviewer provenance: `same-agent-fresh-context`
- Review modes: `code, architecture, workflow`
- Blocking defects: `1`
- Material evidence gaps: `1`
- Non-blocking issues: `0`
- Optional improvements: `0`
- Correction finding IDs: `R0-01`
- Next-slice finding IDs: `none`
- Human-decision finding IDs: `none`
- Detailed review summary: `REVIEW_AGENT_GODOT_VALIDATION_TRUTH_GATE_V1_CLAUDE_SUMMARY.md`
- Follow-up workstream: `agent-godot-validation-truth-gate-v1-review-corrections-1` (not claimed)
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1

### Findings

#### R0-01 — Referenced malformed sidecar can evade preflight when source_file is missing

- Class: `blocking_defect`
- Domain: `implementation`
- Affected acceptance: Referenced tracked `.png.import` sidecars with invalid or missing remap metadata must fail before import.
- Evidence: `invalid_referenced_png_sidecars()` builds reference needles only from the sidecar's parsed `source_file` and `uid`. A tracked `assets/bad.png.import` containing `valid=false`, an empty `dest_files`, a remap path, and no `source_file` was referenced by a tracked scene using `res://assets/bad.png`; `preflight_detail()` returned `None` in a fresh Git fixture. Missing `source_file` is itself not currently an issue, and the sidecar cannot enter the reference set when both source and UID are absent.
- Disposition: `correction`
- Rationale: A referenced malformed sidecar can bypass the gate and proceed to import, directly violating fail-closed resource metadata validation.

### Review Evidence

- `godot_import_preflight_smoke.py`: PASS when run with its temporary directory rooted inside the claimed worktree; the sandbox's `/tmp/.git` marker otherwise made standalone temp projects appear to be in a non-repository.
- `validation_runner_smoke.py`: PASS, including PASS-plus-fatal, missing GDExtension, exact rollback ownership, wrong-owner, near-match, and exit-leak checks.
- `run_validation.py --tag import_truth --json`: PASS, 3/3; actor relationship and Vaultwing resources loaded, generated-region rollback lines were accepted exactly, and shutdown leak lines matched the narrow known patterns.
- `run_validation.py --changed --base 0adbe6265^ --json`: BLOCKED during Godot import. Godot emitted fatal socket bind diagnostics (`_sock == -1`, `ERR_CANT_CREATE`); the inherited config path also failed a save on the first attempt. XDG config/data/cache redirection removed the settings-save error but socket bind diagnostics remained. No changed-file tests ran in this attempt.
- The R0-01 false-negative was independently reproduced in an isolated tracked Git fixture; no reviewed implementation files were changed.

## Review Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `partial`
- Friction severity: `medium`
- What went wrong: The required target-parent changed-file sweep could not pass its import infrastructure gate in the sandbox, and an uncovered missing-source sidecar case falsified the preflight contract.
- Root cause / contributing factors: Godot editor startup attempts socket binds unavailable in this environment; reference association depends on optional metadata fields inside the very sidecar being validated.
- Prevention / pipeline improvement: Add a fixture for referenced malformed sidecars with absent source and UID fields, and use the sidecar's tracked PNG path as a reference candidate; rerun the changed sweep in an environment that permits Godot's editor socket.
- Tooling / docs drift discovered: The preflight smoke's default `/tmp` fixture location conflicts with an environment-provided `/tmp/.git` marker; the test passes when temporary fixtures are rooted inside the claimed worktree.
- Follow-up: `agent-godot-validation-truth-gate-v1-review-corrections-1`
- What worked: The focused import-gated resource trio passed with real Godot loads, and the runner's scoped rollback/fatal fixture matrix passed.
