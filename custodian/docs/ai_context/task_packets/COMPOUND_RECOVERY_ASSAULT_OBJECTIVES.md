# COMPOUND RECOVERY ASSAULT OBJECTIVES

- Packet schema: custodian.task_packet.v2
- Workstream: compound-recovery-assault-objectives
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: review-compound-recovery-damage-coupling
- Locks: compound-assault
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-recovery-assault-objectives
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Direct intermittent enemy assaults through real reachable routes to actual compound infrastructure.
- Completion boundary: Direct intermittent enemy assaults through real reachable routes to actual compound infrastructure. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/systems/core/systems/enemy_director.gd; custodian/game/systems/core/systems/wave_manager.gd; custodian/game/world/placement/world_placement_context.gd; current enemy objective path
- Work surface: custodian/game/systems/core/systems/enemy_director.gd; custodian/game/systems/core/systems/wave_manager.gd; custodian/game/world/placement/world_placement_context.gd; current enemy objective path; minimal adjacent validation and authoritative documentation.
- Change: Map existing director objective and lane selection to stable instance/threshold IDs with real anchors. A sequence: exterior gate/perimeter -> open yard -> powered structure. B: surface entrance -> compartment/tunnel -> service node. Reuse WaveManager composition, enemy local behavior and existing take_damage route. A locked or blocked objective must be re-evaluated via canonical pathing, never enemy teleport or attack through walls. Publish objective/source/damage outcome and allow an explicit recovery interval.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: One deterministic bounded assault in each profile damages target structure from physically valid path and emits traceable aftermath; does not spawn indefinite hordes, reroute cross-layer illegally, or target ghost structures.
- Validation: Director/wave/enemy objective regressions plus NEW profile-specific nav/objective trace. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: New enemy actors, loot economy, full procedural raid strategies.

## Low-token implementation contract

Map existing director objective and lane selection to stable instance/threshold IDs with real anchors. A sequence: exterior gate/perimeter -> open yard -> powered structure. B: surface entrance -> compartment/tunnel -> service node. Reuse WaveManager composition, enemy local behavior and existing take_damage route. A locked or blocked objective must be re-evaluated via canonical pathing, never enemy teleport or attack through walls. Publish objective/source/damage outcome and allow an explicit recovery interval.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
