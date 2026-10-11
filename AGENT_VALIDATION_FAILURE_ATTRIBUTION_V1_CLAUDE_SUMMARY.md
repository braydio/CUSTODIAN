# Agent Validation Failure Attribution V1

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1

## Result

Implemented `custodian/tools/validation/validation_failure_triage.py` as a read-only consumer of canonical validation JSON and the manifest. It preserves candidate and explicitly supplied baseline SHA-256 provenance, exact red/skip IDs, manifest owners/rules, failure diagnostics, selection reasons, duration/timeout, and tier skip blockers. Attribution is `baseline-red`, `candidate-only-red`, or `unknown`; every candidate failure and skip remains blocking, and the CLI does not change source reports or finish gates.

Added ten anti-vacuity tests for H5, Stealth, and NPA-7-shaped reports; baseline-red, candidate-only-red, absent/mismatched/duplicate evidence; fatal/import/timeout/coverage errors; and skip behavior. Added a manifest registration and concise validation recipe/index/backlog documentation.

The first changed-file run exposed `world_transition_handoff` failing and its dependent moment check skipping. Repeated focused diagnostics identified the actual issue: rollback could deliver a deferred `Area2D.body_entered` callback after the Operator had been repositioned. The callback trusted the old overlap event and could submit a second transition against the intentionally missing Hub test scene. Under the user's direction to resolve the failed sweep, the rollback now keeps completion latched until the overlap clears, moves farther beyond the trigger, and validates the Operator's current position against trigger geometry before accepting the callback. The smoke now preserves collision tracking during exit, rejects duplicate rollback requests, and then proves a real second entry succeeds.

## Validation

- `test_validation_failure_triage.py`: 10/10 passed.
- Canonical `validation_runner` and `validation_failure_triage_unit` manifest tests: passed.
- `world_transition_handoff`: six consecutive focused runs passed after the fix.
- Final post-sync `run_validation.py --changed --base origin/main --json`: 45 selected, 45 passed, no skips or uncovered files. The pre-sync changed-file sweep also passed 34/34.
- `check_ai_context.py --json`, packet index, review pairing (68 pairs), Python compilation, manifest JSON parsing, and `git diff --check`: passed.
- The earlier red report was preserved and triaged as blocking/unknown without an explicit baseline; no failure was waived.

## Process Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: success
- Friction severity: high
- What went wrong: The initial changed sweep was red. Early retries surfaced only `TARGET_SCENE_UNAVAILABLE`; tracing the second request and stale Area2D callback was needed to locate the rollback retrigger. Validation also waited behind a competing run holding the shared Godot project lock.
- Root cause / contributing factors: Rollback re-armed Awakening completion before overlap state and deferred body-entered callbacks were settled. The callback did not verify the Operator's current position against the trigger bounds.
- Prevention / pipeline improvement: Keep completion latched until rollback overlap clears; reject stale entry callbacks using current trigger geometry; preserve exact failure attribution and rerun the changed suite after repair.
- Tooling / docs drift discovered: none.
- Follow-up: fixed-in-scope
- What worked: The triage command made the original red failure and dependent skip explicit without changing their blocking status.

## Next Handoff

- Next workstream: review-agent-validation-failure-attribution-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac9c1db-54f4-83e9-b096-2e247319fcf1
- Refresh reason: none
- Next action: Land and archive this implementation, then start its fresh-context paired review.
- Blockers or open questions: none
