# COMPOUND CONNECTED BUNKER BLOCKOUT

- Packet schema: custodian.task_packet.v2
- Workstream: compound-connected-bunker-blockout
- Authoring handoff: auto
- Status: `ready`
- Dispatch: `auto`
- Priority: P1
- Depends on: review-compound-archetype-profile-contract
- Locks: compound-layout
- Kind: implementation
- Review: auto
- Review stage: post-land
- Review modes: code, architecture, runtime, visual
- Paired review workstream: review-compound-connected-bunker-blockout
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Build Type B separate surface housings and a single continuous below-ground room/tunnel topology.
- Completion boundary: Build Type B separate surface housings and a single continuous below-ground room/tunnel topology. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd; custodian/game/world/procgen/proc_gen_tilemap.gd; design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md
- Work surface: custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd; custodian/game/world/procgen/proc_gen_tilemap.gd; design/02_features/procgen/INDOOR_OUTDOOR_PROCGEN_REGIONS.md; minimal adjacent validation and authoritative documentation.
- Change: Generate at least two stable surface-access housings with physically paired subsurface threshold anchors; carve ONE continuously walkable underground floor/wall region containing required functional room IDs and 3+-cell corridor spine, plus compartment threshold cells. Isolate surface and underground physics/nav using real separated coordinate reservation or explicit layer ownership, selected after verifying current ProcGenTilemap implementation. No teleports among underground rooms, no second world generator, deterministic safe egress. Export layer-aware metadata and minimap projection.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: Seven seeds deterministic; three+ rooms traversed underground without room transfer; separate above-ground access points both reach network; no collision/camera or other-layer leaks; all mandatory rooms accessible and no exit softlocks.
- Validation: NEW physical two-layer geometry+navigation smoke, existing persistent_compound_runtime/indoor-outdoor compatibility. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: True seamless Z transition, underground monster director changes and art.

## Low-token implementation contract

Generate at least two stable surface-access housings with physically paired subsurface threshold anchors; carve ONE continuously walkable underground floor/wall region containing required functional room IDs and 3+-cell corridor spine, plus compartment threshold cells. Isolate surface and underground physics/nav using real separated coordinate reservation or explicit layer ownership, selected after verifying current ProcGenTilemap implementation. No teleports among underground rooms, no second world generator, deterministic safe egress. Export layer-aware metadata and minimap projection.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
