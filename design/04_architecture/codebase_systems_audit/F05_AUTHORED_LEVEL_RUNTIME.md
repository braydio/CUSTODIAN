# F05 · Authored level and encounter coordinators

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P1 · **Program maturity:** New candidate; scene-by-scene evidence needed

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `sundered_keep_map.gd` is approximately 129 KB, while `sundered_keep_approach.gd` is approximately 70 KB.
- Authoring pipelines and reusable `LevelLoader` exist; generated and authored route transitions are increasingly unified.
- A roughly 292 KB `meridian_civic_native_prop_catalog.generated.gd` was excluded from debt rankings because generated data size does not establish source complexity.

## Questions the deep audit must answer
- For each level, map scene construction, art registration, collision/navigation, objectives, combat encounters and route handoff authority.
- Identify duplicated hand-written prop/catalog construction that belongs in authored data or reusable build tools.
- Which level scripts merely coordinate content-specific beats versus accidentally owning generic runtime services?
- Which scene-specific dependencies make small level edits trigger broad regression suites?

## Candidate directions (not approved)
- Prioritize one representative level (Sundered Keep) before generalizing patterns to Ash-Bell/Hub.
- Do not abstract bespoke boss/level narrative behaviors into a universal scene framework.
- Keep authored geometry/nav progression unchanged during structural extraction; use exact scene snapshots.

## Evidence and falsification checklist
- Trace Sundered Keep scene entry, encounter, objective, return and unload; compare with shared LevelLoader and route authority.
- Measure duplicated code by behavior/ownership, not just matching literal strings.
- Require exact spawn, collision, event and route snapshots before and after any eventual extraction.

## Existing source of truth and adjacent implementation work
- [`custodian/game/world/sundered_keep/sundered_keep_map.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/world/sundered_keep/sundered_keep_map.gd)
- [`custodian/game/world/approaches/sundered_keep/sundered_keep_approach.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/world/approaches/sundered_keep/sundered_keep_approach.gd)
- [`design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/AUTHORED_LEVEL_AUTHORING_PIPELINE.md)
- [`design/04_architecture/WORLD_TRANSITION_SYSTEM.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/WORLD_TRANSITION_SYSTEM.md)

### Existing task packets (do not duplicate)
- No specific existing implementation packet has been assigned by this audit. Verify adjacent queue ownership before creating one.

### Proposed packet slots (non-executable links to roadmap)
- [CS-F05-A: Representative authored-level owner and state-map extraction, only after level seams are audited](PACKET_ROADMAP.md#cs-f05-a) · proposed filename `CODEBASE_AUDIT_AUTHORED_LEVEL_OWNER_CONTRACT.md`; **not created**

**Dependencies / interference guard:** Coordinate with existing Hub/Ash-Bell/Bridged Falls and route-transition series; preserve bespoke narratives.

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
