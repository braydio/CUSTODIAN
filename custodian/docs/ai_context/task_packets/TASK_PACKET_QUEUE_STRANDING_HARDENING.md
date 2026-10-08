# TASK PACKET QUEUE STRANDING HARDENING

- Packet schema: `custodian.task_packet.v2`
- Workstream: `task-packet-queue-stranding-hardening`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P0`
- Depends on: `none`
- Locks: `agent-dispatch, task-packet-contract, task-packet-index`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, workflow`
- Paired review workstream: `review-task-packet-queue-stranding-hardening`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `substantial workflow/coordination hardening`
- Reviewed main: `2ee26e8d36cc`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Visual review: `none`
- Goal: Eliminate ambiguous task-packet queue states that can make real work disappear from autonomous claiming, and make intentional parking versus dependency gating explicit in dispatcher/status/index output.
- Completion boundary: Make V2 packet queue semantics fail closed around one simple rule: mechanically executable successors are `ready/auto` and are gated only by dependencies/locks/pairing/validation; packets requiring human/design refresh are `draft/manual`; `draft/auto` is invalid for active V2 packets. Update parser/validation/status/index/tests/docs so stranded states are detected before landing and queue output distinguishes eligible, dependency/lock blocked, manual-ready, intentionally parked, claimed, and interrupted-claim recovery states.
- Current measured state: `dispatch.py::_decision()` requires `Status == ready` before any claim. `claim-next` additionally requires `Dispatch == auto`; explicit `claim <id>` may select `ready/manual` but still cannot select `draft`. As a result, `draft/auto` packets are operationally non-claimable forever until manually edited, even after all dependencies archive complete. Live main contained multiple such packets, including mechanically refreshable BF2 and intentionally human-gated OPUI/Bridged-Falls/art packets, so queue intent was encoded inconsistently.
- Evidence: `custodian/tools/agent/dispatch.py`; `custodian/tools/agent/task_packet_contract.py`; `custodian/tools/agent/task_packet_index.py`; `custodian/tools/agent/test_dispatch.py`; `custodian/tools/agent/test_task_packet_contract.py`; `custodian/tools/agent/test_task_packet_index.py`; `custodian/docs/ai_context/task_packets/README.md`; active packet migration on the authoring main.
- Task-specific authority: `task_packet_contract.py` remains the single packet grammar/validation authority; `dispatch.py` remains selection/claim authority; `task_packet_index.py` remains generated queue-index authority. Do not create a second scheduler or separate queue database.
- Work surface: task packet parser/contract validation, dispatcher status rendering/eligibility diagnostics, task-packet index grouping, templates/instructions, focused unit tests, and concise workflow docs.
- Change:
  1. For active `custodian.task_packet.v2` packets, reject `Status: draft` + `Dispatch: auto` as invalid metadata. Legacy archived packets are not retroactively rewritten.
  2. Document/enforce the canonical queue meanings: `ready/auto` = autonomous candidate once dependencies/locks clear; `ready/manual` = implementation-ready but explicit claim only; `draft/manual` = intentionally parked/not implementation-ready and must carry a concrete refresh/decision reason in its body/handoff; `complete` = archived lifecycle result.
  3. Preserve explicit claims of `ready/manual`; do not allow explicit claim to bypass `draft`, dependency, lock, validation, pairing, or claim ownership gates.
  4. Improve `dispatch.py status` so intentionally parked drafts are not mixed into generic BLOCKED output. Render separate bounded groups for READY, CLAIMED, DEPENDENCY/LOCK BLOCKED, MANUAL READY, PARKED DRAFT, INVALID/RECOVERY as appropriate while preserving machine-safe claim behavior.
  5. Make stale/stranding diagnostics actionable: a V2 `draft/auto` must fail validation/index checks with a message directing authors to either `ready/auto` for dependency-gated mechanical work or `draft/manual` for a genuine refresh/human gate.
  6. Add dependency-reference validation sufficient to surface an active packet that names a workstream absent from both active packets and archived complete history; do not require dependencies themselves to be complete at authoring time.
  7. Ensure paired review/correction successors remain ordinary queue entries under the same semantics and cannot be bypassed by depending on a completed review that produced a still-open correction cycle when the successor was explicitly retargeted to the correction re-review.
  8. Update the packet template/README authoring guidance with examples for dependency-gated mechanical refresh versus human/chat refresh. Avoid introducing new mandatory metadata if existing Status/Dispatch + Handoff/Refresh Planning fields suffice.
  9. Add a focused queue-audit test fixture containing: ready/auto no deps; ready/auto incomplete dep; ready/manual; draft/manual human-refresh; invalid draft/auto; duplicate workstream; lock conflict; missing dependency identity; interrupted remote claim; paired review dependency. Assert both status classification and claim eligibility.
- Preserve: Current remote-claim/mutex/worktree safety; priority ordering; exact `agent/<workstream>` identity; explicit manual claim behavior; dependency completion semantics; review pairing validation; validation-reference checks; legacy packet compatibility outside the new active-V2 invariant.
- Non-goals: No autonomous editing/promotion of packet contents after predecessors land. No background scheduler. No automatic human/design decision. No bulk rewriting archived history. No new external state store.
- Acceptance: No active V2 `draft/auto` packet can pass packet validation; mechanical dependency-gated work remains claimable automatically once dependencies complete; intentionally parked work is visibly separated from dependency/lock blockers; explicit `ready/manual` claims still work; active missing dependency identities fail clearly; queue/status/index unit tests cover every canonical state; current packet corpus passes after the one-time metadata migration.
- Validation: Run `python3 custodian/tools/agent/test_task_packet_contract.py`, `python3 custodian/tools/agent/test_dispatch.py`, `python3 custodian/tools/agent/test_task_packet_index.py`, `python3 custodian/tools/agent/check_ai_context.py` or its current equivalent, packet/review-pairing validation, a read-only `python3 custodian/tools/agent/dispatch.py status` fixture/live check, changed-file validation, and `git diff --check`.
- Task overrides: `none`
- Deferred: Automated stale-age reminders/notifications and cross-machine continuous workers.

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `<fill at closeout>`
- Friction severity: `<fill at closeout>`
- What went wrong: `<fill at closeout>`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `<fill at closeout>`
- Tooling / docs drift discovered: `<fill at closeout>`
- Follow-up: `<fill at closeout>`

## Handoff

- Next workstream: `review-task-packet-queue-stranding-hardening`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac57cd9-e070-83ea-b432-7bc0082aef7c
- Summary backlink: Include this exact Authoring chat URL in every durable implementation/review/correction/recovery summary and final Next Handoff.
- Refresh reason: `none`
- Next action: Implement the queue invariant and classification hardening, land, then allow the paired fresh-context review to claim.
- Blockers or open questions: None.
