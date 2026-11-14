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
boundary, pass the dispatcher eligibility, active-claim reconciliation, packet
handoff, and review facts to `evaluate`; follow its action. The helper does not
select packets or claim work: `dispatch.py` remains the assignment authority.
Record implementation and completed-pair milestones with `record-receipt`,
including landed SHA, review status, elapsed time, validation summary, and next
eligibility. Print a short stage update at boundaries; do not dump the queue.

## Routing

1. Inspect the current branch and workstream lifecycle. If already in an
   `agent/<workstream>` checkout, verify its packet, dispatch receipt, branch,
   worktree, and remote state, then resume that workstream. Do not infer ownership
   from `last-claim` alone. A stale or ambiguous receipt requires reconciliation
   or an explicit stop; never create a duplicate claim.
2. If no workstream is active, use the exact immediate successor from the most
   recent durable `Next Handoff`. For a named dependency chain, claim only the
   dispatcher-confirmed eligible predecessor needed to reach that successor.
   Do not jump to unrelated lanes or edit packet metadata to manufacture
   eligibility. `Refresh owner: execution-agent` permits a bounded live-main
   refresh unless it exposes a new human decision.
3. Respect planning refresh, human visual/design/canon decision, manual-dispatch,
   failed-validation, and safety gates. Stop at the gate and provide the exact
   recorded Authoring/Refresh chat URL where present.
4. A paired post-land review is part of the same pair and must run in a fresh
   reviewer context. Once eligible, invoke
   `python3 custodian/tools/agent/paired_review_runner.py <review-workstream-id>`
   from the coordination checkout. Do not directly claim the review from the
   implementation context. Preserve its recovery worktree and run evidence if
   execution fails after claim.
5. Follow the packet and normal `workstream.py` lifecycle through validation,
   summary, commit, landing, and safe root synchronization. Complete and archive
   the associated packet and write its required root closing summary before
   finish. Record the exact landing SHA and accepted review in the boundary
   receipt.
6. After the pair is accepted, inspect its durable `Next Handoff`. In
   `single-pair`, stop even when that successor is ready. In explicit
   `continuous-chain`, continue only to an eligible named successor within the
   requested scope and remaining budget. A paired review or correction cycle
   never consumes an additional pair.
7. Use global `dispatch.py claim-next --agent codex` only when the user
   explicitly requested general-next execution and the current pair is complete
   or blocked. It may select exactly one eligible implementation for the next
   available pair. Never use global fallback to bypass an unresolved review,
   human gate, stale ownership, or validation blocker.

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
