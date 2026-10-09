# F08 · Power, fabrication, defense and logistics

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P2 · **Program maturity:** Integration audit candidate

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- Active simulation modules include `power.gd`, `turret_placement.gd`, `wall_build_system.gd`, `wave_manager.gd` and terminal construction services.
- The master doctrine requires deterministic infrastructure simulation and visible repair/fabrication/defense consequences.
- No independent complexity score or integration failure has been demonstrated yet; potential overlap is a hypothesis.

## Questions the deep audit must answer
- Map ownership of resource consumption, construction commands, power state, repair, fabrication output, defense activation and HUD feedback.
- Find duplicated cost/availability validations in world simulation versus UI/view models.
- Determine whether `WaveManager` is only spawn execution while campaign assault strategy remains separately owned.
- Which observability hooks can prove player-facing outcomes without changing deterministic simulation?

## Candidate directions (not approved)
- Preserve existing state owner per mechanic; extract only demonstrated cross-domain overlap.
- Favor infrastructure choices whose effects can be observed in world and reflected in the campaign outcome.
- Keep new strategic systems out of this cleanup; evaluate separately in feature ROI.

## Evidence and falsification checklist
- Trace one complete resource→fabrication→installation→powered activation→damage→repair cycle.
- Record fixed-step determinism, transaction replay/idempotency and external UI requests.
- Falsify ownership issues with method/callsite evidence before proposing a packet.

## Existing source of truth and adjacent implementation work
- [`custodian/game/systems/core/systems/power.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/core/systems/power.gd)
- [`custodian/game/systems/core/systems/turret_placement.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/core/systems/turret_placement.gd)
- [`custodian/game/systems/core/systems/wave_manager.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/core/systems/wave_manager.gd)
- [`design/00_meta/MASTER_DESIGN_DOCTRINE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/00_meta/MASTER_DESIGN_DOCTRINE.md)

### Existing task packets (do not duplicate)
- No specific existing implementation packet has been assigned by this audit. Verify adjacent queue ownership before creating one.

### Proposed packet slots (non-executable links to roadmap)
- [CS-F08-A: Cross-system infrastructure command and state ownership correction, only if concrete duplicates are found](PACKET_ROADMAP.md#cs-f08-a) · proposed filename `CODEBASE_AUDIT_INFRASTRUCTURE_COMMAND_CONTRACT.md`; **not created**

**Dependencies / interference guard:** Existing power/build/repair contracts and Operator interaction extraction; gameplay values unchanged during audit.

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
