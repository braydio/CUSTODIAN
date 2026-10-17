# CORRECTION: CONNECTED BUNKER VERTICAL TRANSFER AND ISOLATION EVIDENCE (R0-01, R0-02)

- Packet schema: `custodian.task_packet.v2`
- Workstream: `compound-connected-bunker-blockout-review-corrections-1`
- Status: `ready`
- Dispatch: `auto`
- Priority: `P1`
- Depends on: `review-compound-connected-bunker-blockout`
- Locks: `compound-layout`
- Kind: `correction`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, architecture, runtime`
- Paired review workstream: `review-compound-connected-bunker-blockout-review-corrections-1`
- Review cycle: `1`
- Max automatic review cycles: `2`
- Review rationale: `Correct the blocking transfer defect and the isolation evidence gap without adding a second runtime authority`
- Reviewed main: `885961a9cc2f11b5ba7c5f261b22df2476e818b2`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Visual review: `none`
- Parent implementation: `compound-connected-bunker-blockout`; `custodian/docs/ai_context/task_packets/archived/COMPOUND_CONNECTED_BUNKER_BLOCKOUT.md`
- Parent review: `review-compound-connected-bunker-blockout`; `custodian/docs/ai_context/task_packets/archived/REVIEW_COMPOUND_CONNECTED_BUNKER_BLOCKOUT.md`
- Findings addressed: `R0-01, R0-02`
- Affected acceptance: Parent acceptance: separate above-ground access points both reach the underground network; no collision/camera or other-layer leaks.
- Current defect/evidence: The fresh different-agent review (run `20261017T093022Z-53c824e8e5a6`, recovered as `findings`) reported R0-01: the paired `surface_anchor`/`subsurface_anchor` metadata has no runtime consumer, so no housing can be used to reach the underground network and the smoke floods the two regions separately. R0-02: the smoke disables runtime wall collision and navigation baking and makes no camera assertion.
- Goal: Make each paired vertical entry usable in the running game and prove layer isolation on real collision, navigation and camera behavior.
- Completion boundary: A player standing on a housing threshold is moved to its paired underground anchor and back, reversibly, with no state beyond the tile authority; collision, navigation and camera bounds are verified on the real generator.
- Current measured state: `compound_vertical_entries` is exported by `ProcGenTilemap` and drawn on the minimap only. `compound_connected_bunker_smoke.gd` sets `build_runtime_wall_collision = false` and `auto_bake_nav = false`. `Camera.set_authored_map_bounds()` already exists.
- Evidence: R0-01 and R0-02 in the archived parent review; `custodian/game/world/procgen/proc_gen_tilemap.gd`; `custodian/tools/validation/compound_connected_bunker_smoke.gd`; `custodian/game/world/camera.gd`.
- Task-specific authority: `ProcGenTilemap` stays the only tile, region and layer authority. The transfer reads `compound_vertical_entries` and the layer rectangles; it keeps no second copy of layer state.
- Work surface: `custodian/game/world/procgen/proc_gen_tilemap.gd` (read-only accessors and controller attachment); a small new `custodian/game/world/compound/compound_vertical_entry_controller.gd`; `custodian/tools/validation/compound_connected_bunker_smoke.gd`; `custodian/tools/validation/validation_manifest.json`; the connected-bunker section of `design/02_features/procgen/COMPOUND_ARCHETYPES_AND_SECURITY_V1.md`; the packet's own lifecycle metadata.
- Required correction: 1) Reproduce R0-01 first with a failing end-to-end check. 2) Add accessors on `ProcGenTilemap` for vertical entries, the layer at a tile and a layer's world bounds. 3) Add a controller that derives the active layer from the operator position, moves the operator between paired anchors when it stands on the anchor of its current layer, locks out an immediate bounce until the operator leaves the arrival tile, never triggers between underground rooms, and emits a layer-changed signal. 4) Isolate the camera by setting authored bounds to the subsurface content while underground and restoring the previous bounds on return. 5) Extend the smoke to traverse both entries in both directions, assert the camera bounds never intersect the other layer, and verify real wall collision (physics point queries) and real navigation (map path queries) on a subset of seeds.
- Preserve: One tile/navigation authority, the single set of exported level-data keys, the disjoint layer reservation and sealed-cell guard, determinism for seeds 1, 2, 3, 10, 42, 99, 1337, and `legacy`/`walled_yard` behavior.
- Non-goals: No seamless Z transition, no second layer state or generator, no gameplay feel certification, no art, no edit to the archived parent or its review.
- Acceptance: A) Standing on either housing threshold moves the operator to its own paired underground anchor, and standing on that anchor returns it; B) walking across every underground room never changes layer; C) the camera bounds underground never intersect the surface layer and are restored on return; D) with runtime wall collision enabled, separator cells are solid and underground floor is clear; E) with navigation baked, underground rooms are mutually navigable and the surface spawn has no navigation path into the underground; F) determinism, legacy and walled_yard smokes stay green.
- Validation: `compound_connected_bunker`, `compound_archetype_profile`, `persistent_compound_layout`, `persistent_compound_runtime`, `persistent_compound_minimap`; `check_ai_context.py --json`; `validate_review_pairing.py`; `task_packet_index.py`; `run_validation.py --changed --base origin/main --json`; `git diff --check`.
- Task overrides: `none`
- Deferred: A visual presentation of the transfer, audio, and seamless movement between layers.

## Handoff

- Next workstream: `review-compound-connected-bunker-blockout-review-corrections-1`
- Next packet state: `dependency-gated`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ad08a2d-2ae4-83ea-be79-dd8534ffa488`
- Refresh reason: `none`
- Next action: Implement the bounded correction, finish and land normally, then run the exact fresh cycle-1 re-review.
- Blockers or open questions: `none`
