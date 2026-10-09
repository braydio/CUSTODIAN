# F01 · Operator runtime and combat

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P0 · **Program maturity:** Active decomposition, partially implemented

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `game/actors/operator/operator.gd` is approximately 581 KB in the inspected tree; size is a hotspot indicator, not proof of an extraction defect.
- The architecture contract and CURRENT_STATE say F0 dependency injection and F4 Dodge extraction completed. `operator.gd` still exposes substantial orchestration and direct combat/presentation constants.
- F1 loadout, F2 melee, F3 ranged, F5 interaction, F6 recovery and final G shell collapse are already separately packeted, with predecessor gates.

## Questions the deep audit must answer
- Which live state and mutation paths remain actor-owned after F0/F4, and which are intentional CharacterBody2D/chassis responsibilities?
- Are melee, ranged, loadout and presentation clocks duplicated or only mediated by the facade? Identify actual call sites and state mutation owners.
- Which moving-but-committed animation cases currently slide or freeze lower-body cadence? Verify with deterministic replay plus sparse Moment Forge evidence.

## Candidate directions (not approved)
- Prefer finishing existing F1–F6/G program in dependency order rather than a competing blanket `operator.gd` split.
- Keep fixed-step movement, public compatibility facade, and single simulation/presentation authorities; remove obsolete bridges only after consumer proof.
- Separate gameplay-equivalent extraction from feel tuning: composition fixes may travel with domain extraction, balance changes require later explicit decisions.

## Evidence and falsification checklist
- Capture function/line/debt baseline using existing `operator_architecture_debt_audit.py --json`, runtime path and animation authority reports.
- Run focused action/guard/dodge/melee/ranged/Field Patch tests for the exact slice; final G gate owns `--final` audits.
- Record net eliminated actor-owned state, public API compatibility, and validation-manifest reassignment; identify any left-behind temporary seams.

## Existing source of truth and adjacent implementation work
- [`design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/OPERATOR_RUNTIME_ARCHITECTURE.md)
- [`custodian/game/actors/operator/operator.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/actors/operator/operator.gd)
- [`custodian/docs/ai_context/CURRENT_STATE.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/CURRENT_STATE.md)

### Existing task packets (do not duplicate)
- [`OPERATOR_LOADOUT_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_MELEE_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_MELEE_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_RANGED_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RANGED_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_INTERACTION_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_RECOVERY_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RECOVERY_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_RUNTIME_SHELL_COLLAPSE`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RUNTIME_SHELL_COLLAPSE.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F01-A: Post-extraction Operator ownership/debt verification, only if existing Slice G does not close evidence gaps](PACKET_ROADMAP.md#cs-f01-a) · proposed filename `CODEBASE_AUDIT_OPERATOR_POST_G_VERIFY.md`; **not created**

**Dependencies / interference guard:** Existing Operator program and its current review gates; do not bypass queued F1–F6/G.

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
