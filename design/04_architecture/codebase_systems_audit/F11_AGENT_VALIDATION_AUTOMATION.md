# F11 · Agent execution, validation and paired review handoff

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
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

## Candidate directions (not approved)
- Design a small orchestration adapter around existing dispatcher/workstream/next semantics, not another queue.
- Prefer different reviewer process/agent; a same-model fresh context is acceptable only under repository contract and transparent provenance.
- Fail closed at human art/canon/UX decisions, missing fresh reviewer, conflicting claims or validation failures; finite retry budgets.
- Keep one active implementation owner and one review owner at a time for this serial program.

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

### Proposed packet slots (non-executable links to roadmap)
- [CS-F11-A: External reviewer-launch/supervision and bounded successor-loop feasibility proof](PACKET_ROADMAP.md#cs-f11-a) · proposed filename `CODEBASE_AUDIT_AUTONOMOUS_REVIEW_RUNNER.md`; **not created**

**Dependencies / interference guard:** P0 queue-stranding correction plus existing dispatch/review contracts; implementation only after worker interface lock.

## Decision lock record
- **Audit verdict:** pending per-claim code/callsite evidence and focused validation; separate confirmed observations from inferred risks.
- **Chosen boundary and owner:** undecided.
- **Selected behavior / game-feel targets:** undecided; none authorized here.
- **Preserved invariants and exact regression recipe:** derive from verified runtime.
- **Documentation drift to correct / defer:** pending current-source reconciliation.
- **User/ChatGPT design approval:** required for subjective or scope-altering decisions; not recorded.
- **Implementation decision:** **UNLOCKED**. No new task packets may be authored, activated or claimed from this item until this record is updated with evidence, an exact scope/non-goals/acceptance contract, and explicit lock.

## Planned next audit action
Conduct the targeted source/callgraph review, run the smallest applicable validation, record metrics and falsification evidence, then return here to lock or reject the candidate directions. After the lock, graduate only the necessary packet through [the roadmap](PACKET_ROADMAP.md) to the repository's actual task-packet directory.
