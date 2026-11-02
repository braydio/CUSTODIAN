# F13 · New-feature return on investment

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P1 · **Program maturity:** Product/design prioritization, not implementation authorization

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- The master design doctrine centers repair/reconstruction, Operator embodiment, meaningful infrastructure, and knowledge-based persistent progression.
- The first full Awakening→Hub→Contract→Campaign→Outcome→return sequence is represented in existing H-series packets.
- Mission diversity, tactical consequences, evidence/reconnaissance, meaningful vehicle roles and loadout tradeoffs were ranked conceptually, not measured with player telemetry.

## Questions the deep audit must answer
- Which existing loop stage is missing or weak enough to prevent a coherent playable vertical slice?
- How can objectives differ through existing infrastructure, combat, route/evidence and return systems rather than new generalized frameworks?
- What are realistic per-feature implementation, art, validation, onboarding and design-decision costs?
- Which additions deepen the repeated campaign loop without violating one-directly-controlled-Operator, partial-outcome and persistence contracts?

## Candidate directions (not approved)
- Highest first: complete first actual campaign cycle and validate outcome/return.
- Next candidate: 2–3 differentiated Contract objectives with partial outcomes and readable infrastructure consequences.
- Later: deeper enemy tactical interplay, evidence/reconnaissance, vehicle utility roles and selective prep/loadout tradeoffs.

## Evidence and falsification checklist
- For each candidate, write explicit player story, loop stage, existing reused mechanics, new authorities, expected art budget and acceptance scenario.
- Rate player impact, reuse, implementation effort, content dependency, regression risk and evidence quality before locking order.
- Confirm no existing design/packet already owns the idea; no newly executable packets until user decision and focused audit closure.

## Existing source of truth and adjacent implementation work
- [`design/00_meta/MASTER_DESIGN_DOCTRINE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/00_meta/MASTER_DESIGN_DOCTRINE.md)
- [`design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md)
- [`design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md)
- [`design/90_codex/README.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/90_codex/README.md)

### Existing task packets (do not duplicate)
- [`HUB_FIRST_SET_INTEGRATION_CLOSEOUT`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F13-A: Differentiated Contract objectives design and vertical-slice feasibility, only after H7](PACKET_ROADMAP.md#cs-f13-a) · proposed filename `CODEBASE_AUDIT_CONTRACT_OBJECTIVES.md`; **not created**

**Dependencies / interference guard:** Functional H7, live mission-loop evidence and explicit player-experience scope lock.

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
