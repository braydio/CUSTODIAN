# F03 · HUD, terminal and command UI

[← Audit overview / index](../CODEBASE_SYSTEMS_AUDIT.md) · [Packet-roadmap registry](PACKET_ROADMAP.md)

> **Audit state:** Initial evidence captured · detailed source-level audit pending  
> **Decision state:** **NOT LOCKED** · no new task-packet authoring authorized  
> **Snapshot:** `main@e089e8b8a099` · October 8, 2026  
> **Method:** live GitHub documentation/source/tree inspection; no Godot runtime tests or playable feel review in this pass.
> **Provisional priority:** P0 · **Program maturity:** New high-friction audit candidate

## Focus boundary
This item audits the named system's responsibility, integration seams, observed friction and relevant game-feel consequences. Existing architecture and implementation packets remain authoritative for already-claimed work. This document is a **diagnostic/decision record**, not a new feature spec or Codex execution instruction.

## Evidence from current inspection
- `game/ui/hud/ui.gd` is approximately 319 KB, the largest non-generated UI GDScript inspected.
- Terminal already has `terminal_command_router.gd`, `terminal_snapshot.gd`, `terminal_world_action_service.gd`, and focused view-model modules.
- Live `ui.gd` imports many specialized modules; file size alone does not tell us whether command policy or simulation mutation remains in CanvasLayer.

## Questions the deep audit must answer
- Inventory UI/HUD/terminal overlap: which UI components own presentation selection state, and where are commands issued?
- Find per-frame refresh loops, direct autoload/scene lookups, duplicate formatting, and UI callbacks that mutate world state without a command seam.
- Determine whether HUD is an integration facade or a stateful second terminal controller. Trace snapshots, signals and return values.

## Candidate directions (not approved)
- Prefer read-only screen-specific projections/view models and explicit command requests; preserve existing terminal services instead of cloning them.
- Extract by one screen/action domain at a time, with closeout and UI behavior snapshots. Do not redesign the aesthetic while extracting ownership.
- Keep actionable information and cognitive load as separate human-reviewed UX decisions after behavior contracts stabilize.

## Evidence and falsification checklist
- Measure counts of direct world writes, autoload lookups, shared mutable UI state, duplicate terminal projection logic, and existing call sites.
- Trace pause, gamepad/keyboard focus, command execution and back navigation; cover terminal open/close in live scene.
- After any later migration, require screenshot/reference and action-equivalence evidence; no hard-coded UI hierarchy churn without a locked design.

## Existing source of truth and adjacent implementation work
- [`custodian/game/ui/hud/ui.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/hud/ui.gd)
- [`custodian/game/ui/terminal/terminal_command_router.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/terminal/terminal_command_router.gd)
- [`custodian/game/ui/terminal/terminal_world_action_service.gd`](https://github.com/braydio/CUSTODIAN/blob/main/custodian/game/ui/terminal/terminal_world_action_service.gd)
- [`design/01_systems/COMMAND_TERMINAL_UI.md`](https://github.com/braydio/CUSTODIAN/blob/main/design/01_systems/COMMAND_TERMINAL_UI.md)

### Existing task packets (do not duplicate)
- No specific existing implementation packet has been assigned by this audit. Verify adjacent queue ownership before creating one.

### Proposed packet slots (non-executable links to roadmap)
- [CS-F03-A: HUD/terminal command-ownership map and extraction contract](PACKET_ROADMAP.md#cs-f03-a) · proposed filename `CODEBASE_AUDIT_HUD_TERMINAL_COMMAND_SEAM.md`; **not created**
- [CS-F03-B: Screen-state and projection consolidation, conditional on the mapped ownership findings](PACKET_ROADMAP.md#cs-f03-b) · proposed filename `CODEBASE_AUDIT_HUD_VIEWMODEL_CONTRACTION.md`; **not created**

**Dependencies / interference guard:** Audit must precede packet creation; avoid conflicting with already-live terminal/view-model APIs.

## Decision lock record
- **Audit verdict:** pending per-claim code/callsite evidence and focused validation; separate confirmed observations from inferred risks.
- **Chosen boundary and owner:** undecided.
- **Selected behavior / game-feel targets:** undecided; none authorized here.
- **Preserved invariants and exact regression recipe:** derive from verified runtime.
- **Documentation drift to correct / defer:** pending current-source reconciliation.
- **User/ChatGPT design approval:** required for subjective or scope-altering decisions; not recorded.
- **Implementation decision:** **UNLOCKED**. No new task packets may be authored, activated or claimed from this item until this record is updated with evidence, an exact scope/non-goals/acceptance contract, and explicit lock.

## Planned next audit action
Conduct the targeted source/callgraph review, run the smallest applicable validation, record metrics and falsification evidence, then return here to lock or reject the candidate directions. After the lock, graduate only the necessary packets through [the roadmap](PACKET_ROADMAP.md) to the repository's actual task-packet directory.
