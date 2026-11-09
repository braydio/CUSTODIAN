---
name: custodian-next
description: Continue the active CUSTODIAN workstream or execute a bounded packet request through its paired review.
---

# CUSTODIAN Next

Use this skill when the user says "next CUSTODIAN task", "claim the next packet",
"continue the workstream", explicitly invokes `$custodian-next`, or selects
**CUSTODIAN Next** from `/skills` / the slash picker.

## Execution boundary

An unqualified invocation is `single-pair`: complete or resume at most one
implementation packet and its required independent paired review, including
bounded correction/re-review cycles. Then stop with a compact result. An active
claimed workstream is resumed and counts as this pair; never claim another packet
while its implementation or required review is unresolved.

Only use `continuous-chain` when the user explicitly requests continuing across
multiple packets. Require an explicit positive `max_pairs`; honor any explicit
workstream scope. Each pair is one implementation/correction plus its paired
review cycle. Never turn an open-ended request into an unlimited run.

The pure routing/budget policy lives in
`custodian/tools/agent/next_execution_boundary.py`. At invocation start, recover
progress for the invocation ID with its `progress` command. At each claim or pair
boundary, pass V2 identity/design-hold availability, active-turn reconciliation,
packet handoff, and review facts to `evaluate`; follow its action. The helper
does not select packets or claim work: V2 `dispatch.py` remains the assignment
authority.
Record implementation and completed-pair milestones with `record-receipt`,
including landed SHA, review status, elapsed time, validation summary, and next
eligibility. Print a short stage update at boundaries; do not dump the queue.

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
5. A paired post-land review is part of the same pair and must run in a fresh
   reviewer context. Once the review packet is published and independent-review
   preflight passes, invoke
   `python3 custodian/tools/agent/paired_review_runner.py <review-workstream-id>`
   from the coordination checkout. Do not directly claim the review from the
   implementation context. Preserve its recovery worktree and run evidence if
   execution fails after claim.
6. Follow the packet and normal `workstream.py` lifecycle through validation,
   summary, commit, landing, and safe root synchronization. Complete and archive
   the associated packet and write its required root closing summary before
   finish. Record the exact landing SHA and accepted review in the boundary
   receipt.
7. After the pair is accepted, inspect its durable `Next Handoff`. In
   `single-pair`, stop even when that successor is ready. In explicit
   `continuous-chain`, continue only to a published named successor with no
   user-owned design hold within the
   requested scope and remaining budget. A paired review or correction cycle
   never consumes an additional pair.
8. Use global `dispatch.py claim-next --agent codex` only when the user
   explicitly requested general-next execution and there is no unfinished
   specifically selected workstream. It may select exactly one available
   implementation for the next pair. V2 authenticates task identity and blocks
   explicit user-owned design holds; legacy status, dependency, claim, and
   session-lock fields do not schedule acquisition. A blocker on selected work does
   not authorize an unrelated fallback. Never use global fallback to bypass an
   unresolved review, human gate, stale ownership, or validation blocker.

Readiness is not execution: authored, published, V2-acquired,
implemented, landed, validated, and closed describe separate lifecycle stages.
Report only the stage supported by current evidence. A successful publication,
compile, or branch landing is insufficient when the packet's user-visible
acceptance evidence is still missing. Preserve original claims, branches,
worktrees, and evidence; never erase or forge review disposition to clear a
lock. Correct defects in their existing workflow owner without speculative
workflow expansion.

## Newly authorized packet pair (publication before claim)

When an authoring handoff specifically says an approved packet/review pair is
still `draft/manual` or exists only in a local authoring branch, do not call the
dispatcher yet and do not ask the user for the validator command. Validate the
implementation and review pair, promote both to `ready/auto` only if human and
design gates are resolved, validate again, regenerate and verify the managed
index, then land the scoped publication through the safe repository procedure.
Fetch and verify the remote packet identity before claiming the exact
implementation. Never claim the paired review early. This does not authorize
promoting arbitrary parked drafts during general-next routing.

## Result

Persist the full completion, process feedback, and `Next Handoff` in the required
root summary. At a stop, return a concise status with the workstream, pair budget
progress, landing/review state, blocker or next eligibility, and summary path.
For a planning refresh, use the exact recorded URL and workstream ID. For a
subjective visual gate, include the exact Dropbox review manifest path and the
review question. Do not emit routine handoffs between pairs during an explicitly
bounded continuous-chain invocation.
