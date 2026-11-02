# F04 · Enemy and non-player actor runtime

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P1 · **Program maturity:** Existing 11-slice non-player program

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `enemy.gd` is approximately 179 KB and `enemy_behavior_state_machine.gd` approximately 33 KB in the inspected tree.
- The architecture explicitly defines six compositional non-player families, not a universal NPC superclass.
- Marine Dash has a reviewed extracted authority; Savage Pounce and Chain are active/dependency-gated migration targets.

## Questions the deep audit must answer
- Which remaining archetype state machines still mutate inside `enemy.gd`? Verify Savage and ordinary melee against live call sites.
- Where are detection/AI intent, hit resolution, reactions, loot and animation semantic identities owned?
- Do allies, fauna, bosses and turrets reuse the same relationship/targetability contracts without inheriting unrelated behavior?

## Candidate directions (not approved)
- Consume NPA-1 through NPA-11 roadmap and author later slices only after earlier API authority is real.
- Keep behavior equivalence and tuning unchanged during extraction; separate enhanced enemy-feel proposals afterward.
- Remove migrated state and private external calls; do not build an abstract 'universal entity' hierarchy.

## Evidence and falsification checklist
- Track actor-state field/function removal, phase parity, focus test ownership and zero duplicated abilities.
- Review target/relationship queries and fallback groups; verify existing Marine/Savage/Grunt encounter tests.
- Measure enemy tell/contact/recovery pacing separately before changing tactics or damage.

## Existing source of truth and adjacent implementation work
- [`design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/04_architecture/NON_PLAYER_ACTOR_RUNTIME_ARCHITECTURE.md)
- [`custodian/game/actors/enemies/enemy.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/actors/enemies/enemy.gd)
- [`custodian/game/actors/enemies/abilities/marine_dash.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/actors/enemies/abilities/marine_dash.gd)

### Existing task packets (do not duplicate)
- [`ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/ENEMY_SAVAGE_POUNCE_ABILITY_EXTRACTION.md) · **existing queue authority; not created by this audit**
- [`ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/docs/ai_context/task_packets/ENEMY_SAVAGE_CHAIN_ABILITY_EXTRACTION.md) · **existing queue authority; not created by this audit**

### Proposed packet slots (non-executable links to roadmap)
- [CS-F04-A: NPA closure verification, only if NPA-11 leaves uncovered shared-actor contracts](PACKET_ROADMAP.md#cs-f04-a) · proposed filename `CODEBASE_AUDIT_NPA_CLOSURE_VERIFY.md`; **not created**

**Dependencies / interference guard:** NPA predecessor review and authoring-chat gates remain authoritative.

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
