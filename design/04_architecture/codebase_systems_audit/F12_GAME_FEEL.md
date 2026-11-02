# F12 · Cross-system game-feel opportunities

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P1 · **Program maturity:** Design candidate ranking, no direct playtest proof

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- The combat and Operator design already emphasizes deterministic contact, animation ownership and readable attack commitment.
- Existing F1–F6 packets include movement-permissive animation-composition improvements; do not double-book them.
- Enemy ability work, vehicle lifecycle and camera policies give concrete starting points, but this audit did not run an interactive playtest.

## Questions the deep audit must answer
- Rank moving upper/lower animation, hit sound/contact VFX, enemy anticipations/recovery, drive feel, camera, interaction acknowledgement, and HUD response by measured failure severity.
- Which problems are truly animation-source issues, which are presentation authority bugs, and which are balance/gameplay tuning?
- How can sparse deterministic capture, controllable scenario replay and human subjective review establish improvement?

## Candidate directions (not approved)
- Treat existing Operator animation composition as highest near-term ROI, followed by enemy readability, hit feedback, vehicles, interaction response and camera.
- Prefer one mechanic/owner per change, with neutral control scenario and no unintended combat balance changes.
- Any subjective art, impact aesthetic or camera feel lock requires explicit user/ChatGPT decision; tests cannot self-approve it.

## Evidence and falsification checklist
- Gather before/after keyframe/timing or input-state traces, contact timestamps and interaction acknowledgement latency.
- Run representative Operator fast/guard/ranged, enemy Marine/Savage, Scout Buggy and terminal/repair Moment Forge scenarios.
- Record observable success criteria and what remains a human aesthetic judgment before future packet authoring.

## Existing source of truth and adjacent implementation work
- [`design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/combat_feel/COMBAT_FEEL_SYSTEM.md)
- [`design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/combat_feel/OPERATOR_MELEE_ATTACK_DRIVE.md)
- [`design/VFX_DESIGN_LOCK.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/VFX_DESIGN_LOCK.md)
- [`design/00_meta/MASTER_DESIGN_DOCTRINE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/00_meta/MASTER_DESIGN_DOCTRINE.md)

### Existing task packets (do not duplicate)
- [`OPERATOR_MELEE_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_MELEE_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_RANGED_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_RANGED_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`OPERATOR_INTERACTION_DOMAIN_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/OPERATOR_INTERACTION_DOMAIN_EXTRACTION.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F12-A: Combat impact/telegraph feel proof, only after baseline and acceptance lock](PACKET_ROADMAP.md#cs-f12-a) · proposed filename `CODEBASE_AUDIT_COMBAT_FEEL_VERTICAL_SLICE.md`; **not created**

**Dependencies / interference guard:** Subjective presentation approval and observed before/after evidence; don't replace existing Operator packet scope.

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
