# F07 · Inventory and equipment UI

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P1 · **Program maturity:** New boundary audit candidate

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `game/ui/inventory/inventory_ui.gd` is approximately 90 KB and includes page/category state plus equipment item-to-weapon-definition mappings.
- Operator F1 is intended to own equipment and mutable per-weapon runtime state, which introduces a critical UI-to-gameplay boundary.
- Persistent recovery and weapon registration are separately designed but not proven implemented by this audit.

## Questions the deep audit must answer
- Which object owns inventory ledgers, equipment selection, carried objects, weapon state and UI category/page selection?
- Does inventory UI modify Operator loadout directly, or request transactions through stable runtime authority?
- Are catalogue mappings and slot policies duplicated between UI, definitions and inventory manager?

## Candidate directions (not approved)
- Await F1 owner contract before assigning equipment mutations; UI should project state and request transactions.
- Separate equipment operation acceptance/denial from cosmetic feedback and input focus policy.
- Do not fold persistent armament registration into inventory merely because both reference items.

## Evidence and falsification checklist
- Map all equipment mutations and inventory signals; test equip/switch/invalid item, pause/controller focus, UI-close and death persistence.
- Compare item/category/slot presentation against canonical definitions and loadout runtime state after F1.
- Prove no duplicate wallet/item/equipment state, no stale UI selection after external inventory changes.

## Existing source of truth and adjacent implementation work
- [`custodian/game/ui/inventory/inventory_ui.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/inventory/inventory_ui.gd)
- [`custodian/game/systems/core/systems/inventory_manager.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/core/systems/inventory_manager.gd)
- [`design/02_features/ui/INVENTORY_PAUSE_MENU_REFINEMENT.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/ui/INVENTORY_PAUSE_MENU_REFINEMENT.md)
- [`design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/operator/PERSISTENT_RECOVERY_AND_ARMAMENT_REGISTRATION.md)

### Existing task packets (do not duplicate)
- [`OPERATOR_LOADOUT_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_LOADOUT_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F07-A: Inventory equipment transaction boundary and view-model reconciliation](PACKET_ROADMAP.md#cs-f07-a) · proposed filename `CODEBASE_AUDIT_INVENTORY_EQUIPMENT_SEAM.md`; **not created**

**Dependencies / interference guard:** Operator F1 and current inventory/registration authority; no UI-driven duplicate equipment simulation.

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
