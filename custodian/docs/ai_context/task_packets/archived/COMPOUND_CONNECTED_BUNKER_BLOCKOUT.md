# COMPOUND CONNECTED BUNKER BLOCKOUT

- Packet schema: custodian.task_packet.v2
- Workstream: compound-connected-bunker-blockout
- Authoring handoff: auto
- Status: `complete`
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

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `yes`
- Completion boundary satisfied: `yes`
- Acceptance satisfied: `yes`
- Superseded/legacy production path disposition: `n/a`
- Evidence: `connected_bunker` now generates geometry `connected_bunker_subsurface_v1`: two stable surface housings with paired vertical-entry anchors, one continuous underground network holding all eight mandatory rooms on a 3-wide spine with a compartment threshold per room, and a solid separator between the layers. `compound_connected_bunker_smoke.gd` passes for seeds 1, 2, 3, 10, 42, 99, 1337 on the planner (three compound sizes) and on the real ProcGenTilemap: underground rooms are traversed over physical floor with no room transfer, both housings reach the network and the outside, and no walkable cell crosses the separator or leaks between layers. Existing compound profile, layout, minimap and runtime smokes still pass; `legacy` and `walled_yard` output is unchanged.

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success`
- Friction severity: `medium`
- What went wrong: `The first real-generator run showed later pipeline stages writing floor through the separator: terrain required-cell reachability repair, the ascent-route walkability enforcement, and the generic constructed interior region (placed over the compound by its fallback position).`
- Root cause / contributing factors: `Underground rooms were terrain-required cells reached only from the surface spawn, and floor writers had no notion of a sealed region.`
- Prevention / pipeline improvement: `Sealed layer cells are refused by every floor writer in ProcGenTilemap, subsurface tiles are excluded from terrain-required cells, and the generic interior region is skipped for a layered compound. The smoke verifies the real generator, not only the planner.`
- Tooling / docs drift discovered: `A fresh worktree has no Godot import cache, so the compound smokes fail to parse until one import is run; the import also leaves unrelated untracked .uid sidecars.`
- Follow-up: `fixed-in-scope`
- What worked: `Bisecting the separator leak per generation stage with a throwaway probe found all three writers quickly.`

## Next Handoff

- Next workstream: `review-compound-connected-bunker-blockout`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: `Run the exact paired post-land review in fresh context; a visual or gameplay judgement stays with the later human visual gate.`
- Blockers or open questions: `none`

