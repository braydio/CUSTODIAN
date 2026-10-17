# COMPOUND WALLED YARD BLOCKOUT

- Packet schema: custodian.task_packet.v2
- Workstream: compound-walled-yard-blockout
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
- Paired review workstream: review-compound-walled-yard-blockout
- Review cycle: 0
- Max automatic review cycles: 2
- Review rationale: independently landable cross-system change requiring fresh-context review
- Reviewed main: 9b8ae05581e3194876d8b4763946d1f74d77fa50
- Authoring chat: https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488
- Visual review: conditional
- Goal: Make Type A a secure, close-packed compound with physically enclosed perimeter, two authorized entries and traversable yard.
- Completion boundary: Make Type A a secure, close-packed compound with physically enclosed perimeter, two authorized entries and traversable yard. All listed acceptance cases must pass on the real runtime.
- Current measured state: At reviewed baseline, only the original semantic campus is implemented. Archetypes and connected full recovery loop are not shipped; inspect latest main and predecessor review changes before editing.
- Evidence: design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md; existing system files named under Task-specific authority.
- Task-specific authority: custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd _place_rooms_attempt()/ _connect_rooms(); custodian/game/world/procgen/proc_gen_tilemap.gd; persistent_compound_layout_v1.json
- Work surface: custodian/game/world/compound/rooms/persistent_compound_layout_planner.gd _place_rooms_attempt()/ _connect_rooms(); custodian/game/world/procgen/proc_gen_tilemap.gd; persistent_compound_layout_v1.json; minimal adjacent validation and authoritative documentation.
- Change: For walled_yard profile ONLY, cluster independent room footprints with distinct exterior door IDs, reserve >=22% open service-yard circulation and valid fabrication/construction anchors. Create a continuous perimeter boundary in the actual floor/wall collision layer with exactly enumerated primary and secondary accessible gate gaps. Use existing generated wall/nav ownership, no PNG-alpha collision or extra grid. Export explicit perimeter, gate, courtyard and building doorway metadata with stable IDs. Preserve Operator clearance/required corridors and routes to all mandatory rooms.
- Preserve: One tile/navigation authority, room IDs and legacy default, player identity, existing infra/power/resource/wave owners, current Carrow routing, 32px grid and approved art.
- Non-goals: No independent simulator, automatic art approval/ingest, unrestricted construction, new faction/monitoring UI, or python-sim migration.
- Acceptance: Seven seeds deterministic, boundary closes except authorized gates, all mandatory exterior doors and yard/service routes reachable; both gates open/closed give correct physical crossing, no missing floor/anchor or invalid spawn.
- Validation: Extend legacy planner/runtime validation and NEW closed-perimeter flood fill, ingress and clearance checks. New smoke names are proposed, not currently runnable scripts.
- Task overrides: none
- Deferred: Functional electronics, wall destruction visuals and room furniture.

## Low-token implementation contract

For walled_yard profile ONLY, cluster independent room footprints with distinct exterior door IDs, reserve >=22% open service-yard circulation and valid fabrication/construction anchors. Create a continuous perimeter boundary in the actual floor/wall collision layer with exactly enumerated primary and secondary accessible gate gaps. Use existing generated wall/nav ownership, no PNG-alpha collision or extra grid. Export explicit perimeter, gate, courtyard and building doorway metadata with stable IDs. Preserve Operator clearance/required corridors and routes to all mandatory rooms.

## Closeout

Return changed files, measured acceptance, focused test evidence, documentation drift corrections and independent review link. New art is optional until the later human visual gate.
