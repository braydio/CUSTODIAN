# COMPOUND INTERIOR TRAVERSAL INTEGRATION

- Packet schema: custodian.task_packet.v2
- Workstream: compound-interior-traversal-integration
- Authoring handoff: auto
- Status: draft
- Dispatch: manual
- Priority: P1
- Depends on: review-compound-walled-yard-blockout, review-compound-connected-bunker-blockout
- Locks: compound-traversal
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-interior-traversal-integration
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Make Type A separately accessible building interiors and Type B reversible surface access with one continuous bunker interior.
- Completion boundary: Make Type A separately accessible building interiors and Type B reversible surface access with one continuous bunker interior. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/world/gothic_compound/gothic_compound_map.gd INTERIOR_ROOM_DEFINITIONS (DONOR only); custodian/game/systems/core/systems/contract_world_loader.gd; custodian/game/world/placement/world_placement_context.gd; custodian/game/world/procgen/proc_gen_tilemap.gd
- Work surface: custodian/game/world/gothic_compound/gothic_compound_map.gd INTERIOR_ROOM_DEFINITIONS (DONOR only); custodian/game/systems/core/systems/contract_world_loader.gd; custodian/game/world/placement/world_placement_context.gd; custodian/game/world/procgen/proc_gen_tilemap.gd; minimal adjacent validation and authoritative documentation.
- Change: Extend canonical contract-world binding with profile-specific named thresholds and stable room/layer identity, not the Carrow mini-router. Type A may use bounded reversible off-map enter/exit per independent building; Type B MAY transfer only at surface/subsurface seams, not underground room borders. Preserve ONE Operator, resources/equipment, damage state and active level tick. Update camera/weather/lighting/minimap selection per active layer; fail closed for missing/out-of-bounds entry/return anchors.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: A: traverse/return three distinct interiors. B: enter via housing A, cross three underground rooms continuously, exit via housing B. Multiple revisits retain all state, no bounce, duplicate Operator, backdrop or weather leak.
- Validation: Existing Carrow interior/backdrop and contract-world smokes, NEW layer re-entry/identity fixture. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: Physical Z ramp presentation and camera/radar monitoring.

## Low-token implementation contract

Extend canonical contract-world binding with profile-specific named thresholds and stable room/layer identity, not the Carrow mini-router. Type A may use bounded reversible off-map enter/exit per independent building; Type B MAY transfer only at surface/subsurface seams, not underground room borders. Preserve ONE Operator, resources/equipment, damage state and active level tick. Update camera/weather/lighting/minimap selection per active layer; fail closed for missing/out-of-bounds entry/return anchors.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
