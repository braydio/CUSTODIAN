# Agent Godot Validation Truth Gate V1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1

## Result

Implemented the active packet in `godot_import_preflight.py`, `run_validation.py`, the known warning registry, focused smokes, and manifest ownership. Preflight now rejects checked-out LFS pointers and malformed tracked `.png.import` sidecars when a project text resource references their PNG; unreferenced archived/untracked sidecars do not block import. It checks `valid=false`, remap path, and destination metadata without repairing assets.

The runner now fails on fatal script/parse/resource/GDExtension diagnostics even with a PASS sentinel or zero exit from import. Expected rollback errors are exact full-line patterns scoped to their owning manifest test. Regression controls cover positive rollback, wrong owner, near-match, known shutdown leak diagnostics, and PASS-plus-fatal output.

The first import-gated run exposed a classifier false positive: the generated-region smoke emits a registered shutdown resource-leak diagnostic, which the initial fatal-first ordering rejected. I tightened the known leak lines, kept hard parse/load failures fatal, and reran successfully.

## Validation

- `godot_import_preflight_smoke.py`: PASS; 15 invalid referenced sidecars blocked, missing remap path/destination blocked, and unreferenced/untracked corrupt sidecars ignored.
- `validation_runner_smoke.py`: PASS; false-green diagnostics, zero-exit fatal import, exact owner-scoped rollback and near-miss controls passed.
- Live preflight on this checkout: PASS, no checked-out LFS pointers or malformed referenced sidecars.
- `run_validation.py --tag import_truth --json`: 3/3 passed after one import, including actor relationship, Vaultwing runtime, and generated-region rollback resource loads.
- Final `run_validation.py --changed --base origin/main --json`: 31/31 passed, complete coverage, no skips or infrastructure errors.
- `check_ai_context.py --json`: zero findings; packet index, 67 review-pair checks, Python compilation, JSON parsing, and `git diff --check`: passed.
- No tracked `.png.import` assets changed in this worktree, the root checkout, or other worktrees.

## Process Feedback

- Feedback schema: custodian.task_feedback.v1
- Outcome: success
- Friction severity: medium
- What went wrong: The first import-gated run rejected a known shutdown resource-leak line because generic `ERROR:` fatal precedence ran before its exception; rollback exceptions also lacked test ownership and exact-line anchoring.
- Root cause / contributing factors: Existing warning matching was global substring matching, and the fatal classifier did not distinguish hard parse/load diagnostics from registered shutdown lines.
- Prevention / pipeline improvement: Scope expected rollback patterns to test IDs, anchor exact lines, and exercise positive/wrong-owner/near-match controls alongside PASS-plus-fatal cases.
- Tooling / docs drift discovered: none
- Follow-up: fixed-in-scope
- What worked: One `import_truth` invocation performed preflight/import and loaded all three representative registered scenes/resources before the 30-check changed sweep.

## Next Handoff

- Next workstream: review-agent-godot-validation-truth-gate-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Refresh reason: none
- Next action: Land and archive this implementation, then run its fresh-context paired review.
- Blockers or open questions: none
