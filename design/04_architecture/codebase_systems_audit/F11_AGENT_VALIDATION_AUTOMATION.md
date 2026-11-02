# F11 · Agent execution, validation and paired review handoff

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** source-level reviewer-launch audit complete  
> **Decision state:** **LOCKED** · CS-F11-A implementation/review pair authorized  
> **Snapshot:** `main@7eddb322aca7` · October 9, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P1 · **Program maturity:** Repository control plane exists; worker spawning unproven

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `dispatch.py`, `workstream.py`, `workflow_control.py` and review contract/validation utilities exist with substantial focused tests.
- The AGENTS/lifecycle contracts require isolated worktrees, push-first recovery, normal auto landing and a fresh paired-review context.
- `custodian-next` already specifies same-series successor routing, review correction/re-review, and human stop gates; whether a persistent external orchestrator launches the reviewer automatically is not established.

## Questions the deep audit must answer
- Which concrete entrypoint launches and supervises an independent reviewer process/session after `finish`?
- Can a primary worker continue after reviewer pass/fail without user message relay and without reusing implementation context?
- Can review-cycle, stranded queue, resource budget, concurrency lock and human-gate states be tested end-to-end?
- Can it resume after process crash without duplicate claims, duplicate corrections or lost receipts?

## Locked direction

- Add a small synchronous orchestration adapter around the existing dispatcher/workstream/Next-Handoff semantics; do **not** create another queue and do **not** embed model spawning inside `workstream.py finish`.
- When the exact same-series successor is a paired review, the outer runner preflights the installed Codex CLI, claims that exact review packet through the existing dispatcher, then launches a **fresh non-interactive `codex exec --ephemeral` process** with the claimed review worktree as cwd.
- The Codex reviewer reconstructs authority only from durable repository evidence: root/local AGENTS, the review packet, archived implementation packet + summary, landed diff/live main, and required tests. It does not receive or resume the implementation session transcript.
- The runner waits synchronously. Raw Codex execution/log output is stored outside the worktree under Git-common-directory workflow state so review teardown cannot erase supervision evidence.
- `workstream.py finish` remains a deterministic landing/teardown primitive and never becomes dependent on Codex availability, model/network health, or auth.
- Review claim exclusivity continues to come from the existing dispatcher/remote claim CAS + workstream mutex. The runner may not invent its own claim authority.
- Fail closed before claim if no usable `codex` executable/exec interface exists. If Codex fails after a successful claim, preserve the review workstream as recoverable active state and report its branch/worktree/run log instead of deleting/reclaiming it.
- A completed review's durable `Next Handoff` returns to the parent workflow. Correction implementation runs in an ordinary execution context; every paired re-review is again launched through the fresh Codex runner.
- Human visual/canon/UX/planning gates remain stop boundaries. No implicit global-queue hopping and no automatic review beyond the packet's finite correction-cycle limit.

## Evidence and falsification checklist
- Inspect actual runner/process management, credentials isolation, live independent-review initiation and durable receipt/recovery semantics.
- Run mocked temporary-repository pass/fail/re-review/crash/retry cases; then a harmless end-to-end docs-only rehearsal.
- Prove no implicit global queue hopping and no direct mutation of reviewed implementation during independent review.

## Existing source of truth and adjacent implementation work
- [`custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/AGENT_WORKSTREAM_LIFECYCLE.md)
- [`.agents/skills/custodian-next/SKILL.md`](https://github.com/braydio/CUSTODIAN/blob/main/.agents/skills/custodian-next/SKILL.md)
- [`custodian/tools/agent/dispatch.py`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/tools/agent/dispatch.py)
- [`custodian/tools/agent/workflow_control.py`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/tools/agent/workflow_control.py)
- [`custodian/docs/ai_context/task_packets/README.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/README.md)

### Existing task packets (do not duplicate)
- [`TASK_PACKET_QUEUE_STRANDING_HARDENING`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/TASK_PACKET_QUEUE_STRANDING_HARDENING.md) · **existing queue authority; not created by this audit**

### Authorized packet
- [`CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`](../../../custodian/docs/ai_context/task_packets/CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md) · CS-F11-A external paired-review launch/supervision implementation.
- [`REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`](../../../custodian/docs/ai_context/task_packets/REVIEW_CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md) · fresh-context paired review.

**Dependencies / interference guard:** P0 queue-stranding correction plus existing dispatch/review contracts; implementation only after worker interface lock.

## Decision lock record
- **Audit verdict:** the repository already has durable queue identity, remote claim CAS, isolated worktrees, finite review/correction lineage, persistent summaries, and same-series `Next Handoff` routing. The missing seam is only the fresh external reviewer process launch/supervision.
- **Chosen boundary and owner:** `custodian/tools/agent/paired_review_runner.py` (exact private filename may vary only if a stronger existing naming convention is found during implementation) owns preflight, exact review claim, fresh Codex process launch, supervision evidence, and post-process state verification. It does not own packet selection policy beyond the explicitly supplied review successor and does not own landing.
- **Selected behavior:** synchronous local `codex exec --ephemeral` fresh review; durable repo evidence only; no implementation-session resume; exact claimed review worktree; no background daemon required.
- **Preserved invariants and regression recipe:** existing dispatcher is the sole claim authority; `workstream.py finish` behavior is unchanged; paired reviewer may not patch reviewed implementation; review/correction cycle caps remain enforced; user gates fail closed; crash/nonzero leaves recoverable claim state. Prove missing-binary-before-claim, exact-review claim, duplicate-spawn refusal, fresh/ephemeral invocation, nonzero recovery, successful pass, correction handoff, human-gate stop, no global queue hop, and durable run-log survival in temporary-repo tests plus one harmless docs-only rehearsal.
- **Documentation drift:** lifecycle/skill currently says “fresh reviewer context” but has no concrete launcher. CS-F11-A owns that missing executable seam and the documentation update after it lands.
- **User/ChatGPT design approval:** approved in the recorded authoring conversation on 2026-10-09: use Codex Exec to run paired reviews automatically when the execution chain reaches them.
- **Implementation decision:** **LOCKED / AUTHORIZED.** Implement only CS-F11-A and its paired review; do not broaden into a persistent general worker, replacement queue, remote service, or model-provider abstraction.

## Planned next audit action
Execute the authorized CS-F11-A packet and independent paired review. Use its result to decide whether later persistent-worker orchestration needs any additional packet; no follow-up is pre-authorized.
