# F06 · Campaign, Hub, continuity, death and recovery

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P1 · **Program maturity:** Foundation implemented; end-to-end program incomplete

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `CAMPAIGN_FLOW_AND_GAME_LOOP.md` defines Compound→Hub→Contract→Campaign→Outcome→Hub return and insists on exactly-once outcome ownership.
- H-series H2–H7 packets exist; final integration closeout is not established complete in the inspected queue.
- CURRENT_STATE reports R1 death handoff completed, with R2 Post recovery/reintegration depending on reviewed H6 return.

## Questions the deep audit must answer
- Who owns active campaign phase, committed outcome, Hub mutation, Operator death receipt, and persistent recovery state?
- Can repeated callbacks, interrupted loads or failed generation double-apply outcomes or spawn duplicate Operators?
- Which persistence/registration contracts are implemented versus still design-only? Trace live death/return rather than assuming from packet intent.

## Candidate directions (not approved)
- Complete existing H2–H7 and R2 before proposing a broader campaign refactor.
- Preserve single Operator identity, one outcome application and distinct Hub/Compound/Campaign authorities.
- Feature expansion should favor partial outcomes and evidence interpretation after the first real loop works.

## Evidence and falsification checklist
- Verify production boot through Awakening, first Hub, accepted Contract, exact campaign generation, outcome, Hub return and death recovery.
- Run reroute/re-entry/death/retry adversarial tests including duplicate invocation and failed-transition cases.
- Cross-check active campaign docs against actual implementation milestones; annotate planned not deployed states.

## Existing source of truth and adjacent implementation work
- [`design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/CAMPAIGN_FLOW_AND_GAME_LOOP.md)
- [`design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/HUB_FIRST_SET_IMPLEMENTATION_ROADMAP.md)
- [`design/02_features/operator/PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/operator/PERSISTENT_RECOVERY_IMPLEMENTATION_ROADMAP.md)

### Existing task packets (do not duplicate)
- [`HUB_AWAKENING_CONTEXT_HANDOFF`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_AWAKENING_CONTEXT_HANDOFF.md) · **existing queue authority; not created by this audit**
- [`HUB_CAMPAIGN_RETURN`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_CAMPAIGN_RETURN.md) · **existing queue authority; not created by this audit**
- [`HUB_FIRST_SET_INTEGRATION_CLOSEOUT`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/HUB_FIRST_SET_INTEGRATION_CLOSEOUT.md) · **existing queue authority; not created by this audit**
- [`CUSTODIAN_POST_RECOVERY_REINTEGRATION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/CUSTODIAN_POST_RECOVERY_REINTEGRATION.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F06-A: Cross-series outcome/death-return adversarial integration audit, only if H7/R2 do not already cover it](PACKET_ROADMAP.md#cs-f06-a) · proposed filename `CODEBASE_AUDIT_CAMPAIGN_RETURN_ADVERSARIAL.md`; **not created**

**Dependencies / interference guard:** H2–H7, R1/R2 review and persistent-recovery progression are existing source of truth.

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
