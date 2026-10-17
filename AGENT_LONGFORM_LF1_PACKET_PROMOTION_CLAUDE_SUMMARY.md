# Longform LF1 Packet Promotion and Dispatcher Gate

Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62

## Result

Reused the existing PR #70 design and packet files. The planning publication is
on `origin/main` at `0475b31eb030617aaacba972f0549a2798af3146`, with the eight
implementation/review packets initially visible as `draft/manual`. The latest
main reconciliation changed the design's reviewed-main SHA to
`029c31b0396842bc566a5616c46ab03c0696ad80`; the publication itself is the
current main commit and does not change workflow APIs.

All four implementation/review pairs passed targeted authoring preflight while
draft/manual. LF1 also passed after authorized promotion to `ready/auto`. That
preflight exposed a packet-authoring defect: its review `TASK OVERRIDE` differed
from the canonical review template by a missing possessive. The LF1 review
packet now copies the exact canonical bounded scope. `task_packet_index.py`
updated the managed README; LF2–LF4 remain draft/manual. The architecture,
backlog, and FILE_INDEX describe those states. No executable longform runner or
skill has been installed.

## MC1 ownership evidence and stop condition

Current main's MC1 packet is `draft/manual`, but `dispatch.py audit` classifies
`agent-mission-control-data-model-v1` as `claimed` because
`origin/agent/agent-mission-control-data-model-v1` exists. OR1 reports
`agent-workflow` held by that workstream, and LF1 declares the same lock. The
dispatcher audit also reports LF1 as `parked_draft` before this promotion lands.

Read-only evidence: the remote MC1 branch points to `59a1176ce01c1c2f8282a5d1f5df912771b913ab`, an ancestor of current main; no remote
`dispatch-claims/agent-mission-control-data-model-v1` ref exists. Its attached
worktree `/home/braydenchaffee/Projects/.custodian-worktrees/agent-mission-control-data-model-v1-20261012T050753Z-d21e8fbdf9fb`
is dirty only with two untracked `.uid` files. RunTrace
`20261012T050753Z-d21e8fbdf9fb` records null packet/agent at direct start,
`remote_claim_released`, and `start_completed`; no live PID was present at
inspection. This is retained/stranded branch ownership, not evidence of a live
dispatcher claim. The dispatcher still treats the remote branch as claimed, so
do not claim LF1 or alter MC1's branch, packet, worktree, or lock. Stop here
until its owner/recovery path resolves that ownership.

## Validation

- Four targeted implementation/review authoring preflights: PASS.
- LF1 targeted preflight after `ready/auto` promotion and canonical override correction: PASS.
- `task_packet_index.py --write` and check: PASS; LF1 appears in managed Ready/Auto view.
- `validate_review_pairing.py`: PASS (66 pairs).
- `check_ai_context.py --json`: PASS, 0 findings.
- Publication lifecycle test: `task_packet_contract_unit`, 27 tests passed.
- `git diff --check`: PASS.
- Moment Forge/runtime tests: not applicable; documentation and packet metadata only.

Root checkout remains unsynchronized because it has a user edit at
`custodian/game/actors/operator/operator.gd` and is behind `origin/main`; its
state is preserved. No unsafe synchronization was attempted.

## Process Feedback
- Feedback schema: custodian.task_feedback.v1
- Outcome: partial
- Friction severity: medium
- What went wrong: the review packet's bounded commit override was not byte-for-byte aligned with the current canonical template, so the ready/auto preflight initially failed.
- Root cause / contributing factors: PR-authored manual packets were not exercised through the stricter auto-review metadata gate before promotion.
- Prevention / pipeline improvement: preflight paired review packets under their intended `ready/auto` metadata before publication/promotion; use the canonical override text verbatim.
- Tooling / docs drift discovered: dispatcher branch presence is treated as claim evidence even after the recorded direct-start claim ref is released; this leaves stale branches capable of retaining narrow packet locks.
- Follow-up: agent-longform-session-core-v1
- What worked: dispatcher audit, RunTrace, remote ref inspection, and attached-worktree status together separated live claim evidence from stranded branch ownership without modifying MC1.

## Next Handoff
- Next workstream: agent-longform-session-core-v1
- Next packet state: dependency-gated
- Refresh owner: none
- ChatGPT/user planning refresh required: no
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acc5e5e-018c-83ea-8617-ec4c15de7d62
- Refresh reason: none
- Next action: after MC1's owner/recovery path resolves the retained branch/worktree, fetch and audit current main, verify LF1 remains ready/auto, and claim LF1 with the actual executor identity `codex` only when the dispatcher reports it eligible.
- Blockers or open questions: retained MC1 remote branch at `59a1176ce01c1c2f8282a5d1f5df912771b913ab` is classified claimed and holds `agent-workflow`; exact owner is not evidenced in RunTrace (`agent: null`).
