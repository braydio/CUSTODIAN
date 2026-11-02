# F02 · Procedural generation and Contract-world installation

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P0 · **Program maturity:** Parallel phased decomposition and optimization

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `proc_gen_tilemap.gd` is approximately 483 KB, yet the procgen subtree already has about 100 GDScript files; integration-facade ownership is the issue to test.
- `ContractWorldLoader` is approximately 104 KB; placement-context foundation exists, and domain placement extractions plus loader contraction have explicit packets.
- CURRENT_STATE records recent startup, spawn-residency, ingress-clearance and production-scene corrections; new extraction must not regress their ordering.

## Questions the deep audit must answer
- Separate generation semantics, acceptance, paint/streaming realization, authored-claim reservation and world-installation mutation by state owner.
- Which `ProcGenTilemap` and loader helper paths are truly duplicated versus intentionally thin adapters?
- Does generation still use presentation TileMap layers as working memory? Audit after generation-state/claim predecessors, not from historical snapshots.
- Which performance costs are actual runtime hot spots versus presumed from source size?

## Candidate directions (not approved)
- Consume existing V1 extraction/soak and future V2 evidence; do not create a third competing procgen roadmap.
- Keep accepted-world contract, canonical walkability, main playable component and spawn/clearance rules invariant through facade changes.
- Make render/presentation optimization decisions only after render attribution, benchmarks and deterministic fixed-seed parity.

## Evidence and falsification checklist
- Capture fixed seeds, accepted-world fingerprints, startup ordering receipts, spawn fail-closed negatives, and route/ingress snapshots.
- Run S1 baseline/comparison and targeted streaming, residency, layout and production-world boot smokes before whole-series soak.
- Verify removed duplicate authority and manifest ownership, not just reduced facade line count.

## Existing source of truth and adjacent implementation work
- [`design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md)
- [`custodian/game/world/procgen/proc_gen_tilemap.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/world/procgen/proc_gen_tilemap.gd)
- [`custodian/game/systems/core/systems/contract_world_loader.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/systems/core/systems/contract_world_loader.gd)
- [`custodian/game/world/placement/README.md`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/world/placement/README.md)

### Existing task packets (do not duplicate)
- [`PROCGEN_TILEMAP_FACADE_CONTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_TILEMAP_FACADE_CONTRACTION.md) · **existing queue authority; not created by this audit**
- [`PROCGEN_GENERATION_DATA_MODEL_AUDIT`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_GENERATION_DATA_MODEL_AUDIT.md) · **existing queue authority; not created by this audit**
- [`PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_AUTHORED_CLAIM_REGISTRY_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`CONTRACT_WORLD_LOADER_CONTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/CONTRACT_WORLD_LOADER_CONTRACTION.md) · **existing queue authority; not created by this audit**
- [`PROCGEN_RENDER_ATTRIBUTION_V1`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_RENDER_ATTRIBUTION_V1.md) · **existing queue authority; not created by this audit**
- [`PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/PROCGEN_RUNTIME_OPTIMIZATION_V2_SERIES_AUTHORING.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F02-A: Cross-boundary generation→placement→realization parity audit after existing contractions, only if gaps survive](PACKET_ROADMAP.md#cs-f02-a) · proposed filename `CODEBASE_AUDIT_WORLD_HANDOFF_PARITY.md`; **not created**

**Dependencies / interference guard:** Existing procgen V1, placement P-series, D-series and review gates; no speculative owner/API cutover.

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
