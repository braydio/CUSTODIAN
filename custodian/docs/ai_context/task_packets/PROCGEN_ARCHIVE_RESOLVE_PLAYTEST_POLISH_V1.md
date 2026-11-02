# PROCGEN ARCHIVE RESOLVE PLAYTEST POLISH V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-playtest-polish-v1`
- Status: `blocked`
- Dispatch: `manual`
- Priority: `P1`
- Depends on: `none`
- Locks: `procgen-archive-resolve-presentation, procgen-world-presentation`
- Kind: `implementation`
- Review: `auto`
- Review stage: `post-land`
- Review modes: `code, runtime, visual`
- Paired review workstream: `review-procgen-archive-resolve-playtest-polish-v1`
- Review cycle: `0`
- Max automatic review cycles: `2`
- Review rationale: `human gameplay exposed presentation-composition defects that objective AR1-AR4 smokes did not prove; implementation changes shader/timing/world layering and needs a fresh technical pass plus explicit external human visual approval`
- Reviewed main: `cf03b238416fb06c71a4af946242eb9ccf58228a`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Visual review: `required`
- Goal: Make the live Archive Resolve frontier read as unresolved CUSTODIAN world-space rather than black streaming squares, make the graphite/brass resolve legible at gameplay scale, slow ordinary first-resolution enough to perceive it, and ensure unresolved cells visually occlude the full world presentation that occupies them, including props, mobs, structures, walls and existing cliff/fascia presentation, without moving gameplay authority into the effect.
- Completion boundary: Done when the literal Contract sandbox preserves the reviewed AR1-AR4 request/commit/frontier/settlement authority but presents unresolved space through a readable graphite/soot field with visible restrained brass registration; ordinary first-resolve pacing is materially slower and human-readable; a presentation veil/coverage seam above ordinary world presentation prevents rendered enemies/items/props/structures/cliff faces from floating over unresolved cells while the Operator safety pocket remains readable; existing cliff semantics and AP2 art ownership remain untouched; focused machine checks and one compact renderer handoff pass; and the authoring-chat human reviewer explicitly approves or returns bounded tuning feedback.
- Current measured state:
  - The first ordinary live playtest after the `game.tscn` startup P0 closed ran the literal Contract sandbox successfully, but unresolved areas read primarily as black square/cell holes rather than damaged graphite world-space.
  - The human reviewer could only barely perceive Archive Resolve color/VFX and reported that ordinary resolution completes too quickly to read the brass/dither treatment.
  - Fully rendered props, mobs and structures remain visible over unresolved regions in the live game, breaking the intended illusion that presentation itself is unresolved.
  - Existing cliff/fascia presentation remains fully visible and untreated beside unresolved ground. The cliff art quality itself is owned by AP2 and is not part of this packet.
  - Live defaults in `ProcGenRevealPresentation` are `resolve_starts_per_sec=84`, `resolve_burst_cap=8`, `resolve_duration_sec=0.22`, `reacquisition_duration_sec=0.12`, `veil_color=Color(0.07,0.075,0.085,1)`, `registration_intensity=0.6`, `unresolved_haze_intensity=0.5`, and `semantic_echo_intensity=0.5`.
  - `ArchiveResolveVeil` is a single `MultiMeshInstance2D` at `z_index=2`. Current AR2 validation intentionally requires `ContractMap` to precede World/Enemies, Projectiles, Allies and Items, so ordinary z2 actors/items draw above the veil. That prior layering choice is now rejected by human gameplay evidence.
  - `VoidCliffFace` is a separate `TileMapLayer` owned by `procgen_void_cliff_face.gd`; its paint plan already records each painted fascia cell's originating `frontier_cell`, but Archive Resolve currently does not consume that presentation footprint.
  - The playtest Observatory showed Archive Resolve actively tracking thousands of veil instances, so the defect is presentation/readability/composition rather than an effect-disabled worktree issue.
  - Further human playtest refinement (2026-10-10, same Authoring chat): the existing animation is worth preserving but remains too close to the Operator and visually dominant; individual 32 px cells and a sketchy tiled pattern are obvious; the apparently unloaded/unrequested far field is lifeless; a region starts resolving and leaves scattered late solitary cells. The desired motion is a few LOS-derived acquisition rays/anchors followed by connected, slightly elastic outward currents, not literal GPU ray tracing or independent tile lotteries.
  - Root-cause code inspection: `ProcGenRevealPresentation._start_ready_tiles_paced()` uses a rotating READY queue and token budget without adjacency/cohort ordering, so isolated late starts are currently legal. `ProcGenVisualFrontier` has a separate distance cap of 11 +/-2 tiles, canonical wall LOS, and camera-rect filtering; an increased visual distance must preserve occlusion while staying inside committed availability. `archive_resolve.gdshader` computes noise/dither in world space but each veil cell receives its own progress, so coherent wave shape is not guaranteed by the shader alone.
- Evidence:
  - human playtest screenshots + Dev Observatory report in the Authoring chat on 2026-10-09;
  - `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`;
  - `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`;
  - `custodian/game/world/procgen/streaming/archive_resolve.gdshader`;
  - `custodian/game/world/procgen/streaming/procgen_presentation_class.gd`;
  - `custodian/game/world/procgen/proc_gen_map.tscn`;
  - `custodian/game/world/procgen/proc_gen_tilemap.gd`;
  - `custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd`;
  - `custodian/tools/validation/procgen_archive_resolve_shader_smoke.gd`;
  - `custodian/tools/validation/procgen_archive_resolve_frontier_restraint_smoke.gd`;
  - `custodian/tools/validation/fixtures/archive_resolve_frontier_restraint_moment.gd`;
  - `custodian/tools/iteration/scenarios/procgen/archive_resolve_frontier_restraint_review.json`.
- Task-specific authority:
  - `ProcGenRevealPresentation` remains the only Archive Resolve presentation-state/timing owner.
  - `ProcGenTilemap` remains the adapter from existing streaming request/commit/unload and read-only procgen semantics.
  - `ProcgenVoidCliffFace` remains cliff/fascia paint/geometry authority; Archive Resolve may consume a read-only presentation footprint but must not classify/generate cliff cells independently.
  - gameplay collision, navigation, actor simulation, discovery and chunk lifecycle remain upstream truth and cannot depend on Archive Resolve visibility.
- Work surface:
  - Primary expected edits:
    - `custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd`
    - `custodian/game/world/procgen/streaming/procgen_visual_frontier.gd`
    - `custodian/game/world/procgen/streaming/archive_resolve.gdshader`
    - `custodian/game/world/procgen/proc_gen_map.tscn`
    - `custodian/game/world/procgen/proc_gen_tilemap.gd`
    - `custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd`
    - `custodian/tools/validation/procgen_archive_resolve_shader_smoke.gd`
    - `custodian/tools/validation/procgen_archive_resolve_frontier_restraint_smoke.gd`
    - `custodian/tools/validation/procgen_reveal_presentation_smoke.gd` (if this is the actual live owner smoke; verify filename on main)
    - `custodian/tools/validation/fixtures/archive_resolve_frontier_restraint_moment.gd`
    - `custodian/tools/iteration/scenarios/procgen/archive_resolve_frontier_restraint_review.json`
    - `custodian/tools/validation/validation_manifest.json` only if ownership must expand for a new focused smoke/helper.
  - Directly stale docs at closeout:
    - `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md`
    - `custodian/docs/ai_context/CURRENT_STATE.md`
    - `custodian/docs/ai_context/FILE_INDEX.md`
    - `design/02_features/procgen/PROCGEN_RUNTIME_OPTIMIZATION_ROADMAP.md`.
  - Do not edit AP2/AP3 source-master art or their asset-family contracts.
- Change:
  1. Reproduce the human-playtest composition on the literal renderer before tuning. Capture effective z-order for `ArchiveResolveVeil`, `VoidCliffFace`, `TerrainPresentationFront`, `PropLayer`, representative enemy/item/ambient world nodes, and Operator. Record the exact reason each reported leak is currently visible.
  2. Replace scene-order-dependent concealment with an explicit Archive Resolve world-presentation layer. Preferred implementation: keep one presentation owner/state machine and move or mirror its batched veil into an explicit absolute world z layer above ordinary procgen terrain, walls, cliff/fascia, props/dressing and normal world actors/items, while remaining below the HUD/CanvasLayer. If one layer cannot cover every required world-presentation owner cleanly, a second render primitive may share the exact same owner slots/state/custom data, but it must not introduce a second scheduler, lifecycle, frontier, or semantic state machine.
  3. Preserve Operator readability through the existing committed safety pocket/halo rather than by exempting the whole actor layer. The player must not disappear under unresolved cover at its current valid tile. Normal enemies/items/props whose pixels occupy unresolved cells should be visually occluded by the world veil. Projectiles/combat VFX may be occluded once they travel into unresolved space; do not let that change hit logic or simulation.
  4. Extend Archive Resolve presentation coverage to the existing cliff/fascia footprint without taking cliff authority. Add the narrowest read-only production API on `ProcgenVoidCliffFace` needed to expose painted presentation cells and their existing originating `frontier_cell` relationship (or an equivalent already-owned mapping). `ProcGenTilemap` may adapt this into Archive Resolve companion coverage so painted cliff pixels disappear/resolve with the adjacent owning frontier rather than remaining fully visible over unresolved terrain. Do not infer cliff cells from image alpha or duplicate `configure_from_surface_cells()` classification.
  5. Make unresolved cover visibly graphite rather than near-black in ordinary production lighting. Initial tuning target: raise the veil base to approximately `Color(0.12, 0.135, 0.16, 1)` and strengthen broad low-frequency soot variation. Keep it opaque enough to conceal authoritative pixels. The exact final RGB/contrast may move modestly during required human review, but black/flat cell holes are not acceptable.
  6. Strengthen the brass/amber registration read without turning it into neon UI. Initial target: `registration_intensity ~= 0.8`, `semantic_echo_intensity ~= 0.65-0.75`, and a slightly wider/longer intermittent trace band. Keep the existing aged-brass hue family unless the human review rejects it. Preserve reduced-effects suppression/scaling.
  7. Make visual distance generous without sacrificing genuine occlusion or camera relevance. Initial tuning target:
     - `visual_resolve_radius_tiles = 18` (was 11), `visual_resolve_fringe_tiles = 2` (keep irregularity); review may tune the radius in the 16–20 range. This is the radial eligibility limit, NOT permission to reveal through walls. Canonical wall LOS remains mandatory and opaque geometry still acts as a curtain.
     - Retain `camera_margin_tiles = 2` initially; evaluate camera framing under 1280x720/1600x900 and motion. Prefer extending legitimate visible lead distance over forcing out-of-camera starts.
     - `resolve_starts_per_sec = 48`, `resolve_burst_cap = 8`, `resolve_duration_sec = 0.48`, `reacquisition_duration_sec = 0.20`, `ingress_wave_sec = 1.0` as first renderer/test targets. These are starting points, not a license to cover half the view at once: adjust within approximately 20% after human review. Keep `safety_halo_tiles = 3` unless a measured gameplay-readability reason requires otherwise. Continue never revealing uncommitted tiles.
     - In `procgen_visual_frontier.gd`, keep the one cached, deterministic bounded grid-LOS mask and wall-revision refresh. Enlarging its square window from 11 to 18 increases mask work; profile rebuilt mask time, prioritize camera-relevant probes, and bound work without adding per-tile physics rays, unsynchronized caches or changing wall-authority semantics.
  8. Replace ordinary rotating READY-queue start order with a **bounded LOS-seeded cascade** owned by `ProcGenRevealPresentation`. Recommended implementation contract:
     - Use the existing `ProcGenVisualFrontier` cached visibility and camera eligibility to identify a small number of deterministic, spatially separated acquisition origins (typically 1–3 active origins, chosen based on visible committed READY regions and Operator/camera direction). The term “ray tracing” in the human brief means casting visual survey lines/visibility probes through the existing **grid occlusion mask**, NOT GPU ray tracing, raymarched lighting, physics rays, or a new gameplay visibility system.
     - Each origin seeds a connected wavefront across adjacent **committed and eligible READY** cells. Prefer 4-connected expansion for a readable current; allow only measured, corner-safe diagonal bridging, never crossing an opaque wall or a gap of uncommitted cells.
     - Assign wavefront start priority by graph distance along admitted connectivity + smooth world-space noise + bounded class priority; favor adjacent waiting cells over unrelated isolated singles. Produce overlapping 4–12-cell micro-cascades, not independent random per-cell starts; stagger near-neighbors approximately 30–90 ms to get a soft, slightly elastic traveling current.
     - Share the same presentation-clock token bucket across *all* active waves. Keep starts/frame budgeted and deterministic under different frame rates. New origins may appear when a genuinely separate region enters visibility, but cap concurrent origins and do not allow an old origin to stall a new visible pocket forever.
     - Handle late COMMIT, occluder revision, turns, narrow corridors, unload/reacquisition, ring ingress and lone eligible cells: a late neighbor should join the nearest still-valid wave; true isolated eligible cells should get a bounded fallback/start timeout rather than hang indefinitely. Do not synthesize an uncommitted bridge or resurrect settled veils.
     - Keep the same READY/RESOLVING/settled owner and one pooled MultiMesh. A small focused helper such as `procgen_resolve_wavefront.gd` is appropriate **only** if the graph/front bookkeeping would otherwise bloat the existing presentation owner; helpers receive read-only eligible committed tile sets and emit start ordering, never maintain their own streaming/settlement truth.
     - Add low-frequency **elasticity to the registration front** (a gently bending advance with short trailing brass/soot afterglow), not zoom/scaling/bounce of tile sprites. Wave membership and nearby onset times must be visually coherent so square outlines never become the dominant shape.
  8a. Extend `archive_resolve.gdshader` and owner/material controls to remove the per-cell stencil read during RESOLVING. Render a continuous world-space dissolve field using a small bounded set of active wave-origin/timing parameters or an equivalent batch-friendly coherent front representation. Per-instance data is already allocated to cell hash, reacquisition, semantic class and echo: preserve those contracts or document and regression-test any deliberate packing change. Overlap quads by the existing 1 px margin or a measured safe value, avoid tile lattice/16 px sketch-like semantic echo marks on natural terrain, and ensure registration streaks are coherent *across* adjacent cell boundaries. No screen texture or per-cell particle/Tween required.
  8b. Make genuinely not-yet-requested/unstreamed in-bounds areas present as **quiet unresolved world-space** instead of blank black. Preferred: one bounded camera/world-space procedural graphite underfield behind the per-cell cover, with broad drifting soot, sparse faint archive pressure currents and extremely restrained distant registration glints. It must not imply actual uncommitted terrain geometry, enemy locations or available traversal, reveal hidden semantic classes, cover settled world, or spill across the generated map boundary. Distinguish NOT REQUESTED (pure abstract underfield), REQUESTED UNCOMMITTED (opaque safety cover), COMMITTED READY (echo/cascade eligible), and SETTLED (normal world) in tests. Use no new authored image assets for this initial shader-first attempt; if a mandatory art texture becomes necessary, stop at the Asset Pipeline V2 source-work/manifest gate rather than silently inventing runtime sources.
  9. Update the existing AR2 scene-order validation. It must no longer assert that enemies/items/projectiles necessarily draw above the veil. Replace it with objective effective-z/coverage assertions proving unresolved cover masks representative terrain, cliff/fascia, prop/dressing and enemy/item pixels while the local Operator safety pocket is not covered.
  10. Add/extend focused regression coverage for cliff companion coverage: a painted fascia cell linked to a still-veiled frontier remains concealed; when the owning frontier settles, that fascia coverage releases deterministically; unloading/reacquisition reestablishes the shortened treatment without mutating cliff paint state.
  11. Preserve one bounded owner/material path. No per-cell Node/Tween/Timer growth, no whole-map per-frame scan, no actor-by-actor gameplay visibility authority, and no per-frame physics raycasts. If a helper is needed, keep it render-only and driven by Archive Resolve's existing slot/tile transitions.
  12. Publish one compact required visual handoff to `/CUSTODIAN/visual_review/procgen-archive-resolve-playtest-polish-v1/` with the exact Authoring chat URL. Update the Moment Forge frontier fixture for representative cliff/prop/enemy coverage and three reproducible routes: open plateau, hard-walled corridor/turn, and newly committed disconnected/late-neighbor patch. Include at most two full-frame keyframes plus one contact sheet **and one short minimal motion clip** (needed to judge cascade timing/elasticity), with frame stamps and settings. Ask the human reviewer:
      - Is the reveal comfortably farther ahead, without in-your-face pursuit or visibility through walls?
      - Do 1–3 visible acquisition origins feed coherent, elastic connected currents instead of scattered late solo tiles?
      - Does graphite unresolved/unstreamed world-space have quiet movement/detail without looking like a board/grid or showing false terrain?
      - Is the brass/amber/dither VFX noticeable and expressive, but still subordinate to gameplay?
      - Are props, mobs, structures and cliff/fascia presentation fully masked where unresolved, while the Operator/hazards are readable?
      - Does normal settled world regain exactly its ordinary appearance?
     Stop for the authoring-chat human verdict; do not self-approve these perceptual questions.
- Preserve:
  - AR1 request-before-COMMIT, committed-only settlement, fixed slot pool/fail-open overflow, pause-safe presentation clock and disabled-mode parity;
  - AR3 semantic echo identity and shortened reacquisition semantics;
  - AR4 distance/LOS/camera eligibility architecture (radius tunable to 18 initially), settled-memory monotonicity, ingress visibility corrections and time-based deterministic pacing;
  - `ProcGenTilemap` streaming lifecycle, PREPARE/COMMIT, payload cache, distant unload, collision/navigation and topology authority;
  - AP2 cliff art/content ownership and AP3 surface-art ownership;
  - gameplay actor simulation, targeting, collision and damage regardless of presentation veil;
  - S1 canonical determinism fingerprint `1773840677` unless an independently approved baseline has changed.
- Non-goals:
  - no AP2 cliff art replacement or Asset V2 ingest;
  - no AP3 Rocky/Meridian surface integration;
  - no procgen topology/map-size/biome redesign;
  - no fog-of-war/discovery/quest-information mechanic;
  - no enemy AI, spawn, combat or interest-tier changes;
  - no new VFX texture assets in this shader-first slice; any genuinely required new art is a separate Asset Pipeline V2 gate;
  - no full-screen screen-texture post-process without an explicit refresh gate;
  - no permanent grid, neon hologram, particle storm or bright cyber effect.
- Acceptance:
  1. Literal production/Moment renderer evidence shows unresolved cover is visibly graphite/soot and does not read as flat black cell holes at gameplay scale.
  2. Registration/dither is objectively present during RESOLVING and human review says it is perceptible but restrained.
  3. Ordinary first-resolve uses the revised radius/timing defaults (or human-approved bounded values recorded in the packet/summary); the visual frontier begins noticeably farther ahead than the former 11-tile cap without crossing opaque walls, and reacquisition remains clearly shorter/lighter.
  4. Effective world layering no longer relies on sibling tree order for concealment. Representative terrain, walls, `VoidCliffFace`, foreground presentation, props/items and enemies are visually covered when their screen pixels occupy unresolved cells.
  5. The Operator remains readable/playable within its resolved safety halo and HUD/UI remain wholly unaffected.
  6. Cliff/fascia coverage derives from the existing cliff owner and releases with its owning frontier; no duplicate cliff classifier or gameplay semantic map is added.
  7. Settled terrain/world presentation returns to ordinary art with no residual veil/tint/registration/grid.
  8. Reduced-effects and effect-disabled behavior remain correct and do not change streaming/lifecycle fingerprints.
  9. No per-cell node/material/tween growth and no whole-map per-frame actor/presentation scan are introduced.
  10. Existing AR1-AR4 focused smokes, pause-aware streaming, chunk lifecycle/cache/unload/runtime-health, walkable boundary/void cliff integration and S1 quick remain green.
  11. Required visual handoff (including minimal time-based clip) is published and the user/ChatGPT records an explicit pass or bounded tune request in the Authoring chat before implementation closeout.
  12. In deterministic open-area, T-junction/corner and separated-visibility fixtures, starts form traceable connected micro-cascades from 1–3 seeded fronts; no orphaned independently timed cells appear when eligible committed neighbors exist; a true isolated READY cell still resolves through a bounded fallback. Mutation reverting to the old rotating standalone READY scan must fail this test.
  13. Explicit REQUESTED-but-uncommitted and NOT-REQUESTED in-bounds cases remain visually covered/abstract without disclosing actual world/semantic state, while the Operator safety halo remains readable. Settled cells never re-veil just because they leave the frontier.
  14. Frame-rate/pause/late-COMMIT/unload/reacquisition tests prove wave start order, ownership, bounded queue/memory, budget and deterministic replay. Wall mutation and turn tests prove no through-wall wave propagation. Enlarged LOS mask stays within a measured and documented safe frame-time budget rather than creating a new source of hitches.
  15. Renderer screenshots at intermediate 25%/50%/75% resolution show no prominent 32px cell perimeter or repeated sketch/grid pattern. Human verifies the motion is a restrained traveling current, not a fog wipe or individual square pops.
- Validation:
  - Run `procgen_archive_resolve_shader` first after updating its layering expectations.
  - Run `procgen_archive_resolve_frontier_restraint` (including increased-radius occlusion/camera budget and mask-rebuild cost).
  - Run `procgen_reveal_presentation` (extend for seed count, connected wave order, isolated-cell fallback, no new lifecycle authority and deterministic time budgets).
  - Run `procgen_archive_resolve_semantic_echo` (class identity survives revised shader/wave packing).
  - Run `contract_world_archive_resolve_ingress`.
  - Run `procgen_void_cliff_face` and `procgen_void_cliff_wall_integration`.
  - Run `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_distant_chunk_unload`, and `procgen_runtime_health`.
  - Run S1 quick and require `determinism_ok=true` with fingerprint `1773840677` unless current authority explicitly records a reviewed replacement.
  - Add/extend one targeted cascade regression (register it in `validation_manifest.json` if new): old rotating-queue mutation fails; open room waves, occluded T-junction, 2 disconnected visible pockets, late neighbor, camera edges, generation reset, pause, reacquisition and unrequested abstract field all behave as specified.
  - Run the updated Moment Forge scenario with the minimal timing clip and stepped 25/50/75% frames only after objective checks pass.
  - Publish the required compact external review handoff and wait for the Authoring-chat decision.
  - After human approval/tune integration, run `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred:
  - AP2 replaces the existing cliff art itself; this packet only makes whatever cliff presentation is live participate in Archive Resolve.
  - AP3 integrates Rocky Upland + Meridian surface plates after AP2.
  - The separate loot-toast/HUD overlap is owned by `loot-toast-hud-clearance-v1`.
  - The playtest's modular-ranged-presentation warning and performance/navigation incidents are separate follow-ups and must not be folded into this slice; however enlarged-frontier rebuild CPU cost is directly in scope and must be budgeted.

## 2026-10-14 Split Execution Refresh

Do not claim this broad packet. The user re-scoped it into four lower-token, independently reviewable slices: `procgen-streaming-near-player-priority-v1` -> `procgen-archive-resolve-connected-cascade-v1` -> `procgen-archive-resolve-world-cover-v1` -> `procgen-archive-resolve-smooth-front-v1`. This packet remains active only as historical planning context until the split series closes; it must not compete for the same locks.

## Context Pack

- Repomix: `recommended`
- Include: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md,custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd,custodian/game/world/procgen/streaming/procgen_visual_frontier.gd,custodian/game/world/procgen/streaming/archive_resolve.gdshader,custodian/game/world/procgen/streaming/procgen_presentation_class.gd,custodian/game/world/procgen/proc_gen_map.tscn,custodian/game/world/procgen/proc_gen_tilemap.gd,custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd,custodian/tools/validation/procgen_archive_resolve*_smoke.gd,custodian/tools/validation/procgen_void_cliff*_smoke.gd,custodian/tools/validation/fixtures/archive_resolve_frontier_restraint_moment.gd,custodian/tools/iteration/scenarios/procgen/archive_resolve_frontier_restraint_review.json`
- Purpose: `Keep the render owner, cliff presentation seam, existing AR1-AR4 validation and gameplay-scale review fixture in one bounded implementation context.`

## Completion Truth

- Completion schema: `custodian.task_completion.v1`
- Goal satisfied: `<fill at closeout>`
- Completion boundary satisfied: `<fill at closeout>`
- Acceptance satisfied: `<fill at closeout>`
- Superseded/legacy production path disposition: `AR2's actor-above-veil scene-order invariant is superseded by the human-approved world-presentation concealment contract; AR1-AR4 lifecycle/frontier authority is preserved`
- Evidence: `<fill at closeout>`

## Execution Feedback

- Feedback schema: `custodian.task_feedback.v1`
- Outcome: `success | partial | blocked`
- Friction severity: `none | low | medium | high`
- What went wrong: `human gameplay found black unresolved cells, too-fast/low-contrast resolution, actor/prop/structure leaks, and cliff presentation outside the resolve composition`
- Root cause / contributing factors: `<fill at closeout>`
- Prevention / pipeline improvement: `retain gameplay-scale human review after objective presentation smokes for effects whose quality depends on temporal composition`
- Tooling / docs drift discovered: `active Archive Resolve docs still describe the pre-playtest visual baseline and must be reconciled to the approved post-playtest tuning at closeout`
- Follow-up: `paired fresh-context review`
- What worked: `AR1-AR4 state/streaming separation and existing Moment Forge fixture provide a narrow seam for presentation-only correction`

## Handoff

- Next workstream: `review-procgen-archive-resolve-playtest-polish-v1`
- Next packet state: `ready`
- Refresh owner: `none`
- ChatGPT/user planning refresh required: `no`
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6acfd66f-ade0-83ea-8176-262df8bd4391`
- Refresh reason: `none; implementation has a required in-workstream human visual gate but no new planning gate`
- Next action: `After implementation lands with recorded human visual approval, claim the fresh-context paired technical review.`
- Blockers or open questions: `none at claim time; visual closeout requires the specified authoring-chat human decision`
