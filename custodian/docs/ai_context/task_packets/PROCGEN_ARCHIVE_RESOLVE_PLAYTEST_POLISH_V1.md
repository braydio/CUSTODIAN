# PROCGEN ARCHIVE RESOLVE PLAYTEST POLISH V1

- Packet schema: `custodian.task_packet.v2`
- Workstream: `procgen-archive-resolve-playtest-polish-v1`
- Status: `ready`
- Dispatch: `auto`
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
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
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
    - `custodian/game/world/procgen/streaming/archive_resolve.gdshader`
    - `custodian/game/world/procgen/proc_gen_map.tscn`
    - `custodian/game/world/procgen/proc_gen_tilemap.gd`
    - `custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd`
    - `custodian/tools/validation/procgen_archive_resolve_shader_smoke.gd`
    - `custodian/tools/validation/procgen_archive_resolve_frontier_restraint_smoke.gd`
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
  7. Slow first-contact resolution so the effect is perceptible. Initial production target:
     - `resolve_starts_per_sec = 44`
     - `resolve_burst_cap = 5`
     - `resolve_duration_sec = 0.50`
     - `reacquisition_duration_sec = 0.20`
     - keep `visual_resolve_radius_tiles = 11` and `visual_resolve_fringe_tiles = 2` unchanged for this slice unless the human review explicitly identifies frontier distance as a problem.
     - keep `ingress_wave_sec = 1.0` initially; with the longer cell resolve this naturally yields roughly the locked 1-1.5 second entry read.
     Final timing may be tuned within a bounded ±20% of these targets in response to the required human review without a new planning packet.
  8. Improve unresolved-world texture using shader-only/batched presentation, not new art: use at most a small second scale of world-space noise/soot pressure variation and stronger class-specific evidence echo so unresolved space reads as uncertain world structure rather than a blank fill. Preserve no-screen-texture architecture unless the batched approach is objectively incapable of meeting acceptance and the implementation stops for a refresh rather than silently redesigning the renderer.
  9. Update the existing AR2 scene-order validation. It must no longer assert that enemies/items/projectiles necessarily draw above the veil. Replace it with objective effective-z/coverage assertions proving unresolved cover masks representative terrain, cliff/fascia, prop/dressing and enemy/item pixels while the local Operator safety pocket is not covered.
  10. Add/extend focused regression coverage for cliff companion coverage: a painted fascia cell linked to a still-veiled frontier remains concealed; when the owning frontier settles, that fascia coverage releases deterministically; unloading/reacquisition reestablishes the shortened treatment without mutating cliff paint state.
  11. Preserve one bounded owner/material path. No per-cell Node/Tween/Timer growth, no whole-map per-frame scan, no actor-by-actor gameplay visibility authority, and no per-frame physics raycasts. If a helper is needed, keep it render-only and driven by Archive Resolve's existing slot/tile transitions.
  12. Publish one compact required visual handoff to `/CUSTODIAN/visual_review/procgen-archive-resolve-playtest-polish-v1/` with the exact Authoring chat URL. Use the existing Moment Forge frontier scenario, updated only as needed to include representative cliff/prop/enemy coverage. Evidence budget: at most two full-frame keyframes plus one contact sheet; if a short motion clip is necessary to judge the slower timing, justify it as temporal pacing evidence and keep it to the minimum useful duration. Ask exactly:
      - Does unresolved space read as graphite/soot damaged world-space rather than black square streaming holes?
      - Is the brass/amber registration + dither clearly perceptible but still restrained?
      - Do props, mobs, structures and cliff/fascia presentation stop floating visibly over unresolved cells?
      - Is ordinary first-resolution now slow enough to read without feeling obstructive?
      - Does the resolved world return to ordinary presentation with no persistent tint/grid/VFX?
     Stop for the human/ChatGPT answer; do not self-approve these aesthetic/game-feel questions.
- Preserve:
  - AR1 request-before-COMMIT, committed-only settlement, fixed slot pool/fail-open overflow, pause-safe presentation clock and disabled-mode parity;
  - AR3 semantic echo identity and shortened reacquisition semantics;
  - AR4 11-tile distance/LOS/camera eligibility frontier, settled-memory monotonicity, ingress visibility corrections and time-based deterministic pacing;
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
  - no new VFX texture assets;
  - no full-screen screen-texture post-process without an explicit refresh gate;
  - no permanent grid, neon hologram, particle storm or bright cyber effect.
- Acceptance:
  1. Literal production/Moment renderer evidence shows unresolved cover is visibly graphite/soot and does not read as flat black cell holes at gameplay scale.
  2. Registration/dither is objectively present during RESOLVING and human review says it is perceptible but restrained.
  3. Ordinary first-resolve uses the new slower defaults (or human-approved bounded values recorded in the packet/summary); reacquisition remains clearly shorter/lighter.
  4. Effective world layering no longer relies on sibling tree order for concealment. Representative terrain, walls, `VoidCliffFace`, foreground presentation, props/items and enemies are visually covered when their screen pixels occupy unresolved cells.
  5. The Operator remains readable/playable within its resolved safety halo and HUD/UI remain wholly unaffected.
  6. Cliff/fascia coverage derives from the existing cliff owner and releases with its owning frontier; no duplicate cliff classifier or gameplay semantic map is added.
  7. Settled terrain/world presentation returns to ordinary art with no residual veil/tint/registration/grid.
  8. Reduced-effects and effect-disabled behavior remain correct and do not change streaming/lifecycle fingerprints.
  9. No per-cell node/material/tween growth and no whole-map per-frame actor/presentation scan are introduced.
  10. Existing AR1-AR4 focused smokes, pause-aware streaming, chunk lifecycle/cache/unload/runtime-health, walkable boundary/void cliff integration and S1 quick remain green.
  11. Required visual handoff is published and the user/ChatGPT records an explicit pass or bounded tune request in the Authoring chat before implementation closeout.
- Validation:
  - Run `procgen_archive_resolve_shader` first after updating its layering expectations.
  - Run `procgen_archive_resolve_frontier_restraint`.
  - Run `procgen_reveal_presentation`.
  - Run `procgen_archive_resolve_semantic_echo`.
  - Run `contract_world_archive_resolve_ingress`.
  - Run `procgen_void_cliff_face` and `procgen_void_cliff_wall_integration`.
  - Run `procgen_pause_aware_streaming`, `procgen_chunk_lifecycle`, `procgen_chunk_payload_cache`, `procgen_distant_chunk_unload`, and `procgen_runtime_health`.
  - Run S1 quick and require `determinism_ok=true` with fingerprint `1773840677` unless current authority explicitly records a reviewed replacement.
  - Run the updated Moment Forge scenario with renderer evidence only after objective checks pass.
  - Publish the required compact external review handoff and wait for the Authoring-chat decision.
  - After human approval/tune integration, run `python3 custodian/tools/validation/run_validation.py --changed --json` and `git diff --check`.
- Task overrides: `none`
- Deferred:
  - AP2 replaces the existing cliff art itself; this packet only makes whatever cliff presentation is live participate in Archive Resolve.
  - AP3 integrates Rocky Upland + Meridian surface plates after AP2.
  - The separate loot-toast/HUD overlap is owned by `loot-toast-hud-clearance-v1`.
  - The playtest's modular-ranged-presentation warning and performance/navigation incidents are separate follow-ups and must not be folded into this slice.

## Context Pack

- Repomix: `recommended`
- Include: `design/02_features/procgen/STREAMING_REVEAL_PRESENTATION_V1.md,custodian/game/world/procgen/streaming/procgen_reveal_presentation.gd,custodian/game/world/procgen/streaming/archive_resolve.gdshader,custodian/game/world/procgen/streaming/procgen_presentation_class.gd,custodian/game/world/procgen/proc_gen_map.tscn,custodian/game/world/procgen/proc_gen_tilemap.gd,custodian/game/world/procgen/presentation/procgen_void_cliff_face.gd,custodian/tools/validation/procgen_archive_resolve*_smoke.gd,custodian/tools/validation/procgen_void_cliff*_smoke.gd,custodian/tools/validation/fixtures/archive_resolve_frontier_restraint_moment.gd,custodian/tools/iteration/scenarios/procgen/archive_resolve_frontier_restraint_review.json`
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
- Authoring chat: `https://chatgpt.com/g/g-p-6980439e55688191bcf65f31f1c02d06-custodian/c/6ac40778-bccc-83ea-8932-3a9099cd581d`
- Refresh reason: `none; implementation has a required in-workstream human visual gate but no new planning gate`
- Next action: `After implementation lands with recorded human visual approval, claim the fresh-context paired technical review.`
- Blockers or open questions: `none at claim time; visual closeout requires the specified authoring-chat human decision`
