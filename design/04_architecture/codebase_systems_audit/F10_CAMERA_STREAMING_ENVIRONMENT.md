# F10 · Camera, streaming and environmental presentation

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P2 · **Program maturity:** Specialized owners exist; cross-seam audit pending

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `game/world/camera.gd` is approximately 41 KB; world/environment/procgen streaming have distinct directories and helpers.
- CURRENT_STATE documents Archive Resolve reveal/presentation ownership, procgen streaming and environment exposure contracts.
- Current visual correctness and performance need objective measurement before recommending a new renderer architecture.

## Questions the deep audit must answer
- Trace scene travel, camera context handoff, Operator/vehicle follow, zoom, shake, pause and authored camera-zone overrides.
- Ensure streamed floor/chunk residency cannot silently become canonical collision, navigation or generation authority.
- Where do weather, lighting, world underlays and depth/VFX overlap? Is any environment state maintained twice?

## Candidate directions (not approved)
- Preserve presentation firewall: effects may use semantic world signals but never mutate simulation truth.
- Benchmark/attribute rendering cost before consolidation; define feel-based camera behavior as separate tuned policy.
- Minimize subjective visual review captures and route material art decisions to human/ChatGPT.

## Evidence and falsification checklist
- Reproduce scene transitions and camera ownership, generated-region readiness, chunk edge re-entry and vehicle exit.
- Use existing rendering/streaming counters and minimal Moment Forge keyframes only where pixels matter.
- Measure presentation rebuilds, node/draw-call costs and visibility handback behavior before any structural recommendation.

## Existing source of truth and adjacent implementation work
- [`design/01_systems/CAMERA_SYSTEM.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/01_systems/CAMERA_SYSTEM.md)
- [`design/01_systems/CAMERA_COMBAT_INTEGRATION.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/01_systems/CAMERA_COMBAT_INTEGRATION.md)
- [`design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md)
- [`custodian/game/world/camera.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/world/camera.gd)

### Existing task packets (do not duplicate)
- [`PROCGEN_RENDER_ATTRIBUTION_V1`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_RENDER_ATTRIBUTION_V1.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F10-A: Cross-context camera follow/presentation handoff correction, only if runtime failures are confirmed](PACKET_ROADMAP.md#cs-f10-a) · proposed filename `CODEBASE_AUDIT_CAMERA_HANDOFF.md`; **not created**

**Dependencies / interference guard:** Existing procgen render attribution and current camera/Archive Resolve authorities.

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
