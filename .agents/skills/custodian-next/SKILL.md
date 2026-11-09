---
name: custodian-next
description: Continue the active CUSTODIAN workstream or execute a bounded packet request through checkpoint and standard CI.
---

# CUSTODIAN Next

Use this skill when the user says "next CUSTODIAN task", "claim the next packet",
"continue the workstream", explicitly invokes `$custodian-next`, or selects
**CUSTODIAN Next** from `/skills` / the slash picker.

## Execution boundary

An unqualified invocation is `single-task`: complete or resume at most one
implementation task through a durable turn checkpoint and standard CI/branch
protection. Independent review is optional unless the user requests it or the
change is consequential. Then stop with a compact result. Resume active claimed
work; do not replace unfinished selected work with another packet.

Only use `continuous-chain` when the user explicitly requests continuing across
multiple tasks. Require an explicit positive `max_tasks`; honor any explicit
workstream scope. Never turn an open-ended request into an unlimited run.

The pure routing/budget policy lives in
`custodian/tools/agent/next_execution_boundary.py`. At invocation start, recover
progress for the invocation ID with its `progress` command. At each claim or pair
boundary, pass V2 identity/design-hold availability, active-turn reconciliation,
packet handoff, and review facts to `evaluate`; follow its action. The helper
does not select packets or claim work: V2 `dispatch.py` remains the assignment
authority.
Record implementation and completed-pair milestones with `record-receipt`,
including checkpoint SHA, optional review status, elapsed time, validation
summary, and next eligibility. Print a short stage update at boundaries; do not dump the queue.

## Routing

1. Resolve any workstream the user explicitly named or selected before generic
   routing. Keep that unfinished objective current until its acceptance is
   complete or it reaches a documented genuine blocker. Reconcile and resume
   its existing verified claim when safe; if unclaimed, request its exact
   dispatcher claim. Never replace it with `claim-next` or an unrelated packet.
   For a blocked result, record the exact failed prerequisite and one next
   action that advances the same workstream.
2. Inspect the current branch and workstream lifecycle. If already in an
   `agent/<workstream>` checkout, verify its packet, dispatch receipt, branch,
   worktree, and remote state, then resume that workstream. Do not infer ownership
   from `last-claim` alone. A stale or ambiguous receipt requires reconciliation
   or an explicit stop; never create a duplicate claim.
3. If no workstream is active or explicitly selected, use the exact immediate
   successor from the most recent durable `Next Handoff`. Do not treat this
   relationship as a dispatcher dependency or claim a different predecessor
   only to satisfy legacy queue state. Do not jump to unrelated lanes or edit
   packet metadata to manufacture availability. `Refresh owner: execution-agent` permits a bounded live-main
   refresh unless it exposes a new human decision.
4. Respect planning refresh, human visual/design/canon decision, manual-dispatch,
   failed-validation, and safety gates. Stop at the gate and provide the exact
   recorded Authoring/Refresh chat URL where present.
5. Follow the task and V2 `workstream.py` lifecycle through validation, durable
   handoff, commit/push, checkpoint, and safe root synchronization when
   possible. `finish` is a turn checkpoint/retirement operation, not proof of
   task completion. Standard GitHub CI and branch protection govern landing.
   Run independent review in a fresh context when explicitly requested or
   warranted for consequential work.
6. After the selected task reaches a durable checkpoint, inspect its handoff.
   In `single-task`, stop. In explicit `continuous-chain`, continue only within
   the named scope and remaining budget. A missing advisory selection cursor or
   prior session never blocks resumption.
7. Use global `dispatch.py claim-next --agent codex` only when the user
   explicitly requested general-next execution and there is no unfinished
   specifically selected workstream. It may select exactly one available
   implementation for the next task. V2 authenticates task identity and blocks
   explicit user-owned design holds; legacy status, dependency, claim, and
   session-lock fields do not schedule acquisition. A blocker on selected work
   does not authorize an unrelated fallback. Never use global fallback to bypass
   a human gate, stale ownership, or validation blocker.

Readiness is not execution: authored, published, V2-acquired, implemented,
checkpointed, landed by standard CI/branch protection, validated, and closed
describe separate lifecycle stages.
Report only the stage supported by current evidence. A successful publication,
compile, or branch landing is insufficient when the packet's user-visible
acceptance evidence is still missing. Preserve original claims, branches,
worktrees, and evidence; never erase or forge review disposition to clear a
lock. Correct defects in their existing workflow owner without speculative
workflow expansion.


## Result

Persist the full completion, process feedback, and `Next Handoff` in the required
root summary. At a stop, return a concise status with the workstream, task budget
progress, checkpoint/landing state, blocker or next eligibility, and summary path.
For a planning refresh, use the exact recorded URL and workstream ID. For a
subjective visual gate, include the exact Dropbox review manifest path and the
review question. Do not emit routine handoffs between tasks during an explicitly
bounded continuous-chain invocation.
