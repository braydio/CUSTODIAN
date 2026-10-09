# F09 · Vehicle runtime, class identity and driving feel

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P2 · **Program maturity:** Lifecycle consolidation documented as complete

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `PilotableVehicle` is the canonical lifecycle owner according to CURRENT_STATE; older unused vehicle scripts were removed.
- The Field Scout Buggy Mk I has a class identity, durability, wreckage/restoration semantics and focused smoke coverage.
- `pilotable_vehicle.gd` is approximately 26 KB; the basic lifecycle was recently consolidated, so further splitting is not an automatic priority.

## Questions the deep audit must answer
- Verify control ownership, entering/exiting, camera handback, invalid exit clearance, disable/destroy and recovery through literal production paths.
- Test steering, acceleration, brake and visual response at different surfaces; current correctness alone does not prove satisfying feel.
- Which vehicle classes/features add a meaningful mission role beyond faster traversal?

## Candidate directions (not approved)
- Protect newly consolidated lifecycle from speculative architecture churn.
- Prototype driving feel through configuration/data before expanding classes or rebuilding vehicle foundations.
- Consider road material/terrain feedback only through read-only surface queries, with vehicle physics owning motion.

## Evidence and falsification checklist
- Run lifecycle, Scout class, exit clearance, recovery, and vehicle spawn-path validations.
- Use controlled input replay and bounded in-game driving assessment for steering/braking/response.
- If new art is approved later, specify exact Asset Pipeline V2 family/schema, states, dimensions and source/inbox paths then; this audit authorizes no asset creation.

## Existing source of truth and adjacent implementation work
- [`design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/vehicles/FIELD_SCOUT_BUGGY_MK1.md)
- [`design/02_features/vehicles/VEHICLES.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/vehicles/VEHICLES.md)
- [`design/02_features/vehicles/VEHICLE_RECOVERY_IMPLEMENTATION_ROADMAP.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/vehicles/VEHICLE_RECOVERY_IMPLEMENTATION_ROADMAP.md)
- [`custodian/game/vehicles/pilotable_vehicle.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/vehicles/pilotable_vehicle.gd)

### Existing task packets (do not duplicate)
- No specific existing implementation packet has been assigned by this audit. Verify adjacent queue ownership before creating one.

### Proposed packet slots (non-executable links to roadmap)
- [CS-F09-A: Vehicle handling feel prototype and measurable acceptance, pending playtest/design lock](PACKET_ROADMAP.md#cs-f09-a) · proposed filename `CODEBASE_AUDIT_VEHICLE_HANDLING_FEEL.md`; **not created**

**Dependencies / interference guard:** Recent vehicle lifecycle implementation remains authoritative; no new classes/asset families preapproved.

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
