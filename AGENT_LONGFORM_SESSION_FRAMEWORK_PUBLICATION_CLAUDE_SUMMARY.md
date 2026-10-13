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

MC1 remains `draft/manual` on main. The dispatcher classifies it as `claimed`
because `origin/agent/agent-mission-control-data-model-v1` exists and reports
OR1's `agent-workflow` lock held by MC1. Read-only ownership evidence shows no
remote `dispatch-claims/agent-mission-control-data-model-v1` ref; the attached
worktree is at the remote branch head `59a1176`, an ancestor of current main
`85cabcfe`, with two untracked `.uid` files. RunTrace
`20261012T050753Z-d21e8fbdf9fb` records null packet/agent at direct start,
`remote_claim_released`, then `start_completed`; no active PID was present when
checked. This is stranded/retained workstream ownership rather than a live
dispatcher claim. It is preserved untouched. LF1 also declares `agent-workflow`,
so its implementation claim remains blocked until the existing branch/ownership
gate is resolved by its owner/recovery process. The pair may be promoted only
after this planning publication lands and its pair/design checks are verified;
promotion does not release the lock. Implementation, paired reviews, LF2–LF4,
and the bounded end-to-end runner test remain pending.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: low
- What went wrong: none
- Root cause / contributing factors: a retained MC1 remote workstream branch causes dispatcher claimed/lock accounting although its dispatch claim was released and the packet remains draft/manual.
- Prevention / pipeline improvement: preserve this ownership evidence, do not clean it up automatically, and require owner/recovery resolution before any `agent-workflow` claimant proceeds.
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
- Next action: publish the planning series; then after confirming LF1 authoring/design gates on origin/main, promote only its implementation/review pair to ready/auto. Re-audit and claim only after dispatcher says the agent-workflow lock is clear.
- Blockers or open questions: dispatcher treats `origin/agent/agent-mission-control-data-model-v1` at `59a1176` as claimed and holds `agent-workflow`; its run trace shows the dispatch claim was released, but the attached worktree remains dirty with two untracked `.uid` files. Resolve through that workstream's owner/recovery path. No longform runner or skill is installed.
