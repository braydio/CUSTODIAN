# CORRECTION: CODEBASE AUDIT AUTONOMOUS REVIEW RUNNER

- Packet schema: `custodian.task_packet.v2`
- Workstream: `codebase-audit-autonomous-review-runner-review-corrections-1`
- Status: `complete`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-codebase-audit-autonomous-review-runner`
- Locks: `agent-workflow`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, workflow`
- Paired review workstream: `review-codebase-audit-autonomous-review-runner-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Reviewed main: `97703d85ea7111abfa7b71884813df543a555813`
- Parent implementation: `codebase-audit-autonomous-review-runner`; `custodian/docs/ai_context/task_packets/archived/CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`
- Parent review: `review-codebase-audit-autonomous-review-runner`; `custodian/docs/ai_context/task_packets/archived/REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`
- Findings addressed: `R0-01`
- Affected acceptance: Original acceptance 5 (fresh ephemeral exact-worktree launch), 7 (post-claim launch failure recovery), and 15 (bounded end-to-end rehearsal).
- Current defect/evidence: `paired_review_runner.py` supplies `--sandbox workspace-write` together with `--approve-for-me`. Installed Codex rejects this pair; captured run `20261009T211138Z-1115421a9515/runner-failed-launch.stderr` confirms the launched process exited before review startup.
- Goal: Ensure the runner invokes installed Codex with a supported least-privilege permission option set and can start the fresh review process.
- Completion boundary: Correct only runner preflight/argument construction/documentation and focused fake-Codex tests needed to enforce CLI compatibility. No broader permissions redesign.
- Current measured state: Every current launch includes a mutually exclusive flag pair; the actual runner invocation failed before review startup.
- Evidence: Archived parent implementation packet and summary; parent review receipt finding `R0-01`; Git-common-dir launcher recovery record and stderr; installed `codex exec --help`.
- Task-specific authority: F11 decision lock; dispatcher remains sole claim authority; workstream lifecycle remains sole finish/teardown authority; review lineage remains bounded by the parent cycle cap.
- Work surface: `custodian/tools/agent/paired_review_runner.py`, `custodian/tools/agent/test_paired_review_runner.py`, and any exact lifecycle/validation-manifest text that documents the selected CLI option combination.
- Required correction: Remove `--sandbox` when using `--approve-for-me` (or otherwise choose one supported combination), keep runtime preflight aligned with that choice, and make the fake Codex fixture reject the prohibited combination. Add a captured invocation assertion for the supported vector.
- Preserve: Exact dispatcher claim, duplicate-run mutex, ephemeral process freshness, exact receipt worktree, run evidence outside the task worktree, credential redaction, failure recovery, durable-summary verification, and unchanged `workstream.py finish` authority.
- Non-goals: No persistent worker, queue changes, model/provider redesign, permission escalation, implementation of unrelated findings, or game/runtime changes.
- Acceptance:
  1. `R0-01`: The runner's emitted CLI vector contains no mutually exclusive flag combination according to the installed CLI help.
  2. `R0-01`: A fake Codex executable rejects incompatible option pairs and the success fixture proves the corrected exact vector starts in the claimed worktree with `--ephemeral`.
  3. `R0-01`: A bounded synthetic review launch reaches Codex startup and retains recovery behavior for later failures.
- Validation: Run focused runner tests, dispatch/workstream/review-contract/queue-context suites, `run_validation.py --changed --json`, inspect captured invocation metadata, and run `git diff --check`. A live rehearsal may use only a harmless synthetic review packet and must leave no durable queue residue.
- Task overrides: `none`
- Deferred: Any unrelated runner hardening.

## Delta Rules

- Address only finding `R0-01` from the paired review. Keep the original receipt and finding ID stable.
- Re-review must report `R0-01` as `fixed`, `unresolved`, or `regressed`; new findings use cycle 1 IDs.
- This packet is intentionally `draft/manual`; promotion and dispatch require the authorized task-packet publication process.

## Authoring chat

https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `low`
- What went wrong: The initial combined unittest command used package-style imports unsupported by this repository's test layout; rerunning from `custodian/tools/agent/` passed. No implementation blocker remained.
- Root cause / contributing factors: The runner test imports its sibling module directly and expects the tools directory on `sys.path`.
- Prevention / pipeline improvement: Run focused agent tests from `custodian/tools/agent/`, consistent with the validation recipes.
- Tooling / docs drift discovered: none
- Follow-up: `review-codebase-audit-autonomous-review-runner-review-corrections-1`
- What worked: Fake Codex rejects the incompatible option pair and captures the actual supported invocation, cwd, prompt, output and redaction behavior.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: Removed `--sandbox workspace-write` from preflight and runtime invocation while retaining `--approve-for-me`; updated lifecycle/current-state permission guidance; fake Codex explicitly rejects the incompatible pair and captures the corrected exact launch in the expected worktree. Runner tests passed 11/11; dispatch/workstream/review-contract/queue-context suites passed 140/140; changed-file validation passed all 11 selected checks with complete changed-file coverage and no failures; `git diff --check` passed.

## Next Handoff

- Next workstream: `review-codebase-audit-autonomous-review-runner-review-corrections-1`
- Next packet state: ready
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
- Refresh reason: none
- Next action: After this correction lands and archives complete, invoke `python3 custodian/tools/agent/paired_review_runner.py review-codebase-audit-autonomous-review-runner-review-corrections-1` from the synchronized coordination checkout.
- Blockers or open questions: none

## Independent Review

- Status: `passed`
- Reviewer context: `fresh`
- Reviewer provenance: `different-agent`
- Reviewed landed main: `0235357952c06c0b5f489811cb35d48c949300a4`
- Findings: `R0-01` fixed; no cycle-1 findings.
- Evidence: `REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER_REVIEW_CORRECTIONS_1_CLAUDE_SUMMARY.md`; installed Codex CLI help; captured implementation run `20261009T211138Z-1115421a9515`; runner/dispatcher/workstream/review-contract/task-packet-contract/task-packet-index suites (171 passed); changed-file validation; `git diff --check`.
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac95a34-c8fc-83ea-a2d0-28a1dc72f166
