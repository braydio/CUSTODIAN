# Longform Session Framework Planning Publication

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62

## Result

Published the PR #70 longform architecture and LF1–LF4 implementation/review
packet series as planning documents, reconciled against `origin/main` at
`85cabcfe6aa546fe0eb97d6bc5650c02277bb7d8`. The architecture records that the
existing dispatcher, workstream lifecycle, RunTrace, paired-review runner,
validation runner, and next-execution boundary remain the execution authorities.
It also records live OR1/OR2 and validation-evidence-freshness dependencies and
their current relationship to the longform plan.

All eight packets remain `Status: draft` and `Dispatch: manual`. Targeted
implementation/review authoring preflight passed for each of the four pairs.
The managed index required no changes and does not expose these drafts as
claimable work. The backlog and FILE_INDEX now describe the framework as
planned, clarify the proposed 3-attempt / 3-pair / 180-minute budgets, and state
that ordinary single-pair `$custodian-next` behavior and dispatcher authority
remain unchanged. No runner, skill, or executable workflow is claimed as
implemented.

## Validation and stop condition

- `task_packet_index.py --write` and read-only check: PASS; already up to date.
- Four targeted implementation/review authoring preflights: PASS.
- `validate_review_pairing.py`: PASS (62 existing auto-review pairs).
- `check_ai_context.py --json`: PASS, 0 findings.
- `git diff --check`: PASS.
- Moment Forge: not run — planning/documentation-only publication.
- Runtime/focused implementation tests: not applicable; no executable code was
  added.

The live dispatcher audit on fetched main records the existing
`agent-workflow` lock held by `agent-mission-control-data-model-v1`; LF1 declares
that same lock. Therefore LF1 has not been promoted or claimed, and implementation,
paired reviews, LF2–LF4, and the bounded end-to-end runner test remain pending.
Re-check lock and recovery state through the dispatcher after the lock holder
completes. Do not bypass the lock or change packet metadata to manufacture
eligibility.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: none
- Root cause / contributing factors: LF1 is currently ineligible under an existing live workflow lock.
- Prevention / pipeline improvement: keep proposal packets draft/manual until the live lock and any recovery gates clear; re-audit before promotion.
- Tooling / docs drift discovered: the automation backlog described one-claim dispatcher behavior and continuous-worker deferral without distinguishing bounded longform orchestration; clarified both.
- Follow-up: agent-longform-session-core-v1
- What worked: targeted packet-pair preflight and the existing AI-context/review-pair validators provided a narrow, machine-checkable publication gate.

## Next Handoff
- Next workstream: agent-longform-session-core-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Refresh reason: none
- Next action: after the existing agent-workflow lock and any recovery gate clear, re-audit origin/main, then explicitly authorize/promote the LF1 implementation/review pair through packet preflight and dispatcher procedures.
- Blockers or open questions: agent-workflow lock held by agent-mission-control-data-model-v1; no longform runner or skill is installed.
